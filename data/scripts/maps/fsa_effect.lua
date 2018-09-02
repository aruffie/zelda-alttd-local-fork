local fsa = {}

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

function fsa:render_water_mask(map)
  local cx,cy = map:get_camera():get_position()
  local _,_,l = map:get_hero():get_position() -- TODO : use light layer instead
  local dx,dy = cx % 8, cy % 8
  local w,h = self.map_occ:get_size()
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

function fsa:render_reflection(map)
  reflection:clear()
  local t = sol.main.get_elapsed_time() * clouds_speed;
  local x,y = t,t
  local cw,ch = reflection:get_size()
  local tx,ty = x % crw, y % crh
  for i=-1,math.ceil(crw/cw)+1 do
    for j=-1,math.ceil(crh/ch) do    
      clouds:draw(reflection,tx+i*crw,ty+j*crh)
    end
  end
  do --draw hero reflection
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

function fsa:render_fsa_texture(map)
  fsa_texture:clear()
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

function fsa:apply_effect(game) 
  game:register_event("on_map_changed",function(game,map)
    function map:on_draw(dst)
      --dst:set_shader(shader)
      dst:draw(tmp)
      fsa:render_reflection(map)
      fsa:render_fsa_texture(map)
      local camera = map:get_camera()
      local dx,dy = camera:get_position()
      tmp:draw(dst)
      fsa:draw_clouds_shadow(dst,dx,dy)
    end
  end)
end

return fsa