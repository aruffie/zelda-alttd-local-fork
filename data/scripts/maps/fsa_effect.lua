local fsa = {}

local light_mgr = require("scripts/lights/light_manager.lua")

local tmp = sol.surface.create(sol.video.get_quest_size())
local reflection = sol.surface.create(sol.video.get_quest_size())
local fsa_texture = sol.surface.create(sol.video.get_quest_size())
local clouds = sol.surface.create("work/clouds_reflection.png")
local clouds_shadow = sol.surface.create("work/clouds_shadow.png")
clouds_shadow:set_blend_mode("multiply")

local effect = sol.surface.create"work/fsaeffect.png"
--effect:set_blend_mode"multiply"
local shader = sol.shader.create"water_effect"
shader:set_uniform("reflection",reflection)
shader:set_uniform("fsa_texture",fsa_texture)
tmp:set_shader(shader)
local ew,eh = effect:get_size()

local clouds_speed = 0.01;

-- unused alternative to water color-keying
function fsa:render_water_mask(map)
  local cx,cy = map:get_camera():get_position()
  local _,_,l = map:get_hero():get_position() -- TODO : use light layer instead
  local dx,dy = cx % 8, cy % 8
  local w,h = water_mask:get_size()
  local color = {255,255,255,255}
  water_mask:clear()
  for x=0,w,8 do
    for y=0,h,8 do
      local ground = map:get_ground(cx+x,cy+y,l)
      if blocking_grounds[ground] then
        water_mask:fill_color(color,x-dx,y-dy,8,8)
      end
    end
  end
end

local crw,crh = clouds:get_size()

function fsa:render_reflection(map,outside)
  reflection:clear()
  local t = sol.main.get_elapsed_time() * clouds_speed;
  local x,y = t,t
  local cw,ch = reflection:get_size()
  local tx,ty = x % crw, y % crh
  if outside then
    for i=-1,math.ceil(crw/cw)+1 do
      for j=-1,math.ceil(crh/ch) do    
        clouds:draw(reflection,tx+i*crw,ty+j*crh)
      end
    end
  else
    reflection:fill_color{128,128,128}
  end
  do --draw hero reflection --TODO add other reflections
    local hero = map:get_hero()
    local tunic = hero:get_sprite('tunic')
    local osx,osy = tunic:get_scale()
    tunic:set_scale(osx,-osy)
    local hx,hy = hero:get_position()
    local cx,cy = map:get_camera():get_position()
    local tx,ty = hx-cx,hy-cy
    tunic:draw(reflection,tx,ty)
    tunic:set_scale(osx,osy)
  end
end

local csw,csh = clouds_shadow:get_size()

function fsa:draw_clouds_shadow(dst,cx,cy)
  local t = sol.main.get_elapsed_time() * clouds_speed;
  local x,y = math.floor(t),math.floor(t)
  local cw,ch = dst:get_size()
  local tx,ty = (-cx+x) % csw, (-cy+y) % csh
  for i=-1,math.ceil(csw/cw)+1 do
    for j=-1,math.ceil(csh/ch) do    
      clouds_shadow:draw(dst,tx+i*csw,ty+j*csh)
    end
  end
end

local function get_lights_from_map(map)
  local map_id = map:get_id()
  local lights = {}
  -- Here is the magic: set up a special environment to load map data files.
  local environment = {
  }

  local light_tile_ids = {
    ["wall_torch.1"] = true,
    ["wall_torch.2"] = true,
    ["wall_torch.3"] = true,
    ["wall_torch.4"] = true,
    ["torch"] = true,
    ["torch_big.top"] = true,
  }

  function environment.tile(props)
    if light_tile_ids[props.pattern] then
      --tile is considered as a light
      table.insert(lights,
                   {
                     layer = props.layer,
                     x = props.x + props.width*0.5,
                     y = props.y + props.height*0.5,
                   }
      )
    end
  end

  -- Make any other function a no-op (tile(), enemy(), block(), etc.).
  setmetatable(environment, {
    __index = function()
      return function() end
    end
  })

  -- Load the map data file as Lua.
  local chunk = sol.main.load_file("maps/" .. map_id .. ".dat")

  -- Apply our special environment (with functions properties() and chest()).
  setfenv(chunk, environment)

  -- Run it.
  chunk()
  return lights
end

function fsa:render_fsa_texture(map,outside)
  fsa_texture:clear()
  if not outside then
    fsa_texture:fill_color{255,255,255}
    return
  end
  local cw,ch = fsa_texture:get_size()
  local camera = map:get_camera()
  local dx,dy = camera:get_position()
  local tx = ew - dx % ew
  local ty = eh - dy % eh
  for i=-1,math.ceil(ew/cw)+1 do
    for j=-1,math.ceil(eh/ch) do    
      effect:draw(fsa_texture,tx+i*ew,ty+j*eh)
    end
  end
end

local function create_light(map,x,y,layer,radius,color)
  return map:create_custom_entity{
    direction=0,
    layer = layer,
    x = x,
    y = y,
    width = 16,
    height = 16,
    sprite = "entities/fire_mask",
    model = "light",
    properties = {
      {key="radius",value = radius},
      {key="color",value = color}
    }
  }
end

function fsa:apply_effect(game)
  game:register_event("on_map_changed",function(game,map)
    local outside = map:get_world() == "outside_world"
    if not outside then
      light_mgr:init(map)
      light_mgr:add_occluder(map:get_hero())


      local hero = map:get_hero()
      --create hero light
      local hl = create_light(map,0,0,0,"50","196,128,200")
      function hl:on_update()
        hl:set_position(hero:get_position())
      end
      hl.excluded_occs = {[hero]=true}

      --add a static light for each torch pattern in the map
      local map_lights = get_lights_from_map(map)
      local default_radius = "90"
      local default_color = "193,185,0"

      for _,l in ipairs(map_lights) do
        create_light(map,l.x,l.y,l.layer,default_radius,default_color)
      end

      --TODO add other non-satic occluders
      for en in map:get_entities_by_type("enemy") do
        light_mgr:add_occluder(en)
      end
      for en in map:get_entities_by_type("npc") do
        light_mgr:add_occluder(en)
      end

      --generate lights for dynamic torches
      for en in map:get_entities_by_type("custom_entity") do
        if en:get_model() == "torch" then
          local tx,ty,tl = en:get_position()
          local tw,th = en:get_size()
          local yoff = -8
          local light = create_light(map,tx+tw*0.5,ty+th*0.5+yoff,tl,default_radius,default_color)
          en:register_event("on_unlit",function()
                              light:set_enabled(false)
          end)
          en:register_event("on_lit",function()
                              light:set_enabled(true)
          end)
          light:set_enabled(en:is_lit())
        end
      end

    end
    function map:on_draw(dst)
      --dst:set_shader(shader)
      dst:draw(tmp)
      fsa:render_reflection(map,outside)
      fsa:render_fsa_texture(map,outside)
      local camera = map:get_camera()
      local dx,dy = camera:get_position()
      tmp:draw(dst)
      if outside then
        fsa:draw_clouds_shadow(dst,dx,dy)
      else
        light_mgr:draw(dst,map)
      end
    end
  end)
end

return fsa
