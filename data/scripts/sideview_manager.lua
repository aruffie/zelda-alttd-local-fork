--[[
Sideview manager

This script implements gravity and interaction of the hero with ladders, which are used in sideview maps.

To initialize, just require it in a game setup script, like features.lua, 
   then call map:set_sidewiew(true) in the on_started event of each map you want to be in sideview mode.
   
If you need to make things jump like the hero when he uses the feather, then simply do <your_entity>.vspeed=<some_negative_number>, then the gravity will do the rest.

In the same way, you can make any entity be affected by gravity by adding "has_gravity" in its custom properties.
--]]

local map_meta = sol.main.get_metatable("map")
local hero_meta = sol.main.get_metatable("hero")
local game_meta = sol.main.get_metatable("game")
require("scripts/multi_events")
require("scripts/states/sideview_swim")
local walking_speed = 88
local swimming_speed = 66
local gravity = 0.2
local max_vspeed = 2
local __debug=false

local function debug_print(...)
  if __debug then
    print(...)
  end
end

--[[
  Returns whether there is an entity at given XY coordinates whth the custom property "ladder" set to true.
  Parameters : 
   map, the map object
   x,y, the corrdinates of the point to test
--]]
local function is_dynamic_ladder(map, x,y, layer)
  layer=layer or 0
  for e in map:get_entities_in_rectangle(x,y,1,1) do
    if e:get_type()=="dynamic_tile" and e:get_property("ladder")=="true" then
      return true
    end
  end
  return false
end

--[[
  Returns whether the ground at given XY coordinates is a ladder.
  This is actually a shortcut to avoid multiples instances of "map:get_ground(x,y, layer)=="ladder" in tests.
  Parameters : 
   map, the map object
   x,y, the corrdinates of the point to test
--]]
local function is_ladder(map, x,y, layer)
  layer=layer or 0
  for e in map:get_entities_in_rectangle(x,y,1,1) do
    if e:get_type()=="dynamic_tile" and e:get_property("ladder")=="true" then
      return true
    end
  end
  return map:get_ground(x,y, layer)=="ladder" 
end

--[[
  Sets whether we are in sideview mode in the current map.
  Parameter: enabled (boolean or nil).
--]]
function map_meta.set_sideview(map, enabled)
  map.sideview=enabled or false
end

--[[
  Returns whether the current map is in sideview mode.
--]]
function map_meta.is_sideview(map)
  return map.sideview or false
end

--[[
  Sets the vertical speed on the entity, in pixels/frame.
  Parameter: vspeed, the new vertical speed.
--]]
function map_meta.set_vertical_speed(entity, vspeed)
  entity.vspeed = vspeed
end

--[[
  Returns whether the current vertical speed of the entity, in pixels/frame.
--]]
function map_meta.get_vertical_speed(entity)
  return entity.vspeed or 0
end

--DEBUG : Display the position of the saved ground
--local debug_respawn_surface = sol.surface.create(16,16)
--debug_respawn_surface:fill_color({255,127,0,64})

--map_meta:register_event("on_draw", function(map, dst_surface)
--    -- if map:is_sideview() then
--    local x,y = map:get_camera():get_position()
--    local xx,yy=map:get_hero():get_solid_ground_position()
--    debug_respawn_surface:draw(dst_surface, xx-x-8, yy-y-13)
--    --end
--  end)


map_meta:register_event("on_opening_transition_finished", function(map)
    if map:is_sideview() then
      map:get_hero():save_solid_ground()
    end
  end)


--[[
  Checks if the ground under the top-middle or the bottom-middle points of the bounding box of a given entity is a ladder.
  Returns : xhether a ladder was detected
--]]
local function test_ladder(entity)
  local map=entity:get_map()
  local x,y,layer= entity:get_position() 
  return is_ladder(map, x, y-2, layer) or is_ladder(map, x, y+2, layer)
end

local function check_for_water(entity)
  local map=entity:get_map()
  local x,y,layer= entity:get_position() 
  local bx,by,w,h=entity:get_bounding_box()
  local ox, oy=entity:get_origin()
  --we need to have full clearance of water before we can go down (in sideview section, there is no such thing as a free ground on the side of water pool)
  for i=bx, bx+w-1, 8 do
    --debug_print ("Checking water at ("..i..", "..(by+h)..").")
    if map:get_ground(i,by+h, layer)~="deep_water" then
      return false
    end
  end
  return map:get_ground(bx+w-1, by+h, layer) =="deep_water"

end

-- Check if an enemy sensible to jump is overlapping the hero, then hurt it and bounce.
local function on_bounce_possible(entity)

  local map = entity:get_map()
  local hero = map:get_hero()
  for enemy in map:get_entities_by_type("enemy") do
    if hero:overlaps(enemy, "overlapping") and enemy:get_life() > 0 and not enemy:is_immobilized() then
      local reaction = enemy:get_jump_on_reaction()
      if reaction ~= "ignored" then
        enemy:receive_attack_consequence("jump_on", reaction)
        entity.vspeed = 0 - math.abs(entity.vspeed)
      end
    end
  end
  return entity.vspeed or 0
end

--[[
  This is the core function of the side views : 
  it applies a semi-realistic gravity to the given entity, and resets the vertical speed if :
    we reached a solid obstacle,
    we laanded on top of a ladder
    Parameter : entity, the entity to apply the gravity on.
--]]
local function apply_gravity(entity)
  local x,y,layer = entity:get_position()
  local map = entity:get_map()
  local w,h = map:get_size()
  --update vertical speed
  local vspeed = entity.vspeed or 0 
  if vspeed > 0 then
    vspeed = on_bounce_possible(entity)
  end
  if vspeed >= 0 then
    --Try to apply gravity
    if entity:test_obstacles(0,1) or entity.on_ladder or
    test_ladder(entity)==false and is_ladder(entity:get_map(), x, y+3) then
      --we are on an obstacle, so reset the speed and bail.
      if entity:get_type()=="hero" and y+2<h and entity:test_obstacles(0,1) and map:get_ground(x,y+3,layer)=="wall" then
        entity:save_solid_ground(x,y,layer)
      end
      entity.vspeed = nil
      return false
    end
    entity:set_position(x,y+1)
  else
    -- Try to get up
    if not entity:test_obstacles(0,-1) or map:get_ground(x,y+3,layer) == "prickles" then
      entity:set_position(x,y-1)
    end
  end

  --Update the vertical speed
  if map:get_ground(x,y,layer)=="deep_water" then
    vspeed = math.min (0, vspeed)--Submerges entities have their own fixed time fall timer, so don't cumulate them (unless we remove it and keep it in a central place ?
  else
    vspeed = math.min(vspeed+gravity, max_vspeed)
  end
  entity.vspeed = vspeed

  --Set the new delay for the timer
  return math.min(math.floor(10/math.abs(vspeed)), 100)
end

--Loops through all entities in the map and tries to enable the gravity timer onto them if they met the requirements
local function update_entities(map)  
  for entity in map:get_entities() do
    if entity:is_enabled() then
      -- Check entitites that can fall.
      local is_affected
      local has_property = entity:get_property("has_gravity")
      local e_type = entity:get_type()
      if e_type=="carried_object" or e_type =="hero" then
        is_affected = true
      else
        is_affected = false
      end
      if e_type == "pickable" and entity:get_property("was_created_from_custom_pickable")~="true" then
        --convert to custom entity with same properties
        --debug_print ("Converting a pickable to a custom entity")
        local x, y, layer = entity:get_position()
        local w, h = entity:get_size()
        local ox, oy = entity:get_origin()
        local s=entity:get_sprite()
        local item, variant, savegame_variable=entity:get_treasure()
        local e=map:create_custom_entity({
            x=x,
            y=y,
            layer=layer,
            width=w,
            height=h,
            direction=0,
            sprite=s:get_animation_set(),
            model="pickable_underwater",
            properties = {
              {
                key="has_gravity",
                value="true",
              },
              {
                key="treasure_name",
                value=item:get_name(),
              },
              {
                key="treasure_variant",
                value=tostring(variant),
              },
            },
          })
        if savegame_variable then
          e:set_property(
            {
              key="treasure_savegame_variable",
              value=savegame_variable,
            })
        end
        e:set_origin(ox,oy)
        local sprite=e:get_sprite()
        sprite:set_animation(s:get_animation())
        sprite:set_direction(variant-1)
        sprite:set_xy(0,2) --shift down the visual
        entity:remove()
      elseif has_property or is_affected then  -- Try to make entity be affected by gravity.
        if __debug and not entity.show_hitbox then --DEBUG : draw hitbox information
          entity.show_hitbox = true --Flag me s processed
          local w,h=entity:get_size()
          local s=sol.surface.create(w,h)
          local ox, oy=entity:get_origin()
          local b={255,0,0}
          local c={0,255,0}
          --draw the hitbox
          s:fill_color(b, 0, 0, w,1)
          s:fill_color(b, 0, h-1, w,1)
          s:fill_color(b, 0, 0, 1,h)
          s:fill_color(b, w-1, 0, 1, h)
          --draw the origin (representing the actual position)
          s:fill_color(c, 0, oy, w, 1)
          s:fill_color(c, ox, 0 ,1,h)
          entity.debug_hitbox=s
          function entity:on_post_draw(camera)
            local cx,cy=camera:get_position()
            local x,y=entity:get_bounding_box()
            entity.debug_hitbox:draw(camera:get_surface(), x-cx, y-cy)
          end
        end
        if entity:get_type()~="hero" and entity.water_processed == nil and entity.vspeed == nil and entity:test_obstacles(0,1) and check_for_water(entity) then
          --Force the entity to get down when in a water pool
          entity.water_processed=true
          sol.timer.start(entity, 50, function()
              entity.water_processed=nil
              local x,y=entity:get_position()
              entity:set_position(x,y+1)
            end)
        end

        if entity.vspeed and entity.vspeed<0 or not entity:test_obstacles(0,1) then
          --Start gravity effect timer loop
          if entity.gravity_timer==nil then
            entity.gravity_timer=sol.timer.start(entity, 10, function()
                local new_delay = apply_gravity(entity)
                if not new_delay then
                  entity.gravity_timer=nil
                end
                return new_delay
              end)
          end
        end
      end
    end
  end
end

local function is_on_ground(entity, dy)
  dy = dy or 0
  local x,y = entity:get_position()
  return entity:test_obstacles(0, 1) or not test_ladder(entity) and is_ladder(entity:get_map(), x, y+3)
end


--Respawn wnen falling into a pit
hero_meta:register_event("on_position_changed", function(hero, x,y,layer)
    local map = hero:get_map()
    if map:is_sideview() then
      local w,h = map:get_size()
      if y+3>=h then
        hero:set_position(hero:get_solid_ground_position())
        hero:start_hurt(1)
      end
    end
  end)


--[[
  TODO find a better explanation for this core function
  
  Updates the internal movement of the hero, by reading the currently pressed arrow keys commands.
  This is also where it get attached to the ladder if it is against one by pressing
  
  Then, updates the sprite accordinf to the new parameters
  Parameter : hero, the hero object.
--]]

local function update_hero(hero)
  local movement = hero:get_movement()
  local game = hero:get_game()

  local function command(id)
    return game:is_command_pressed(id)
  end
  local state, cstate = hero:get_state()
  local x,y,layer = hero:get_position()
  local map = game:get_map()
  local speed=88
  local hangle, vangle
  local can_move_vertically = true
  local _left, _right, _up, _down
  local ladder=test_ladder(hero)


  -------------------------
  --Manage command inputs--
  -------------------------
  if command("up") and not command("down") then
    _up=true
    if map:get_ground(x,y,layer)=="deep_water" then 
      speed = swimming_speed
    elseif ladder == true  and not is_on_ground(hero) then
      hero.on_ladder = true
      if is_dynamic_ladder(map, x,y,layer) then
        --Lower the speed on dynamic tile-based ladders since they have plain "traversable" ground
        --debug_print "UP-erride"
        speed = 52
      end
    else
      can_move_vertically = false
    end
  elseif command("down") and not command("up") then
    ---debug_print "LEFT"
    _down=true
    if map:get_ground(x,y, layer) == "deep_water" then
      speed = swimming_speed
    elseif ladder==true or is_ladder(map, x, y+3, layer) then
      hero.on_ladder = true
      if is_dynamic_ladder(map, x,y,layer) then
        --Lower the speed on dynamic tile-based ladders since they have plain "traversable" ground
        --  debug_print "DOWN-erride"
        speed=52
      end
    else
      --debug_print "no V-Move"
      can_move_vertically = false
    end
  end

  --check if we are on the top of a ladder
  if not (ladder==true or is_ladder(map, x, y+3)) then
    hero.on_ladder = false
  end

  if command("right") and not command("left") then
    _right=true
    hangle = 0
    speed=walking_speed
    if map:get_ground(x,y,layer)=="deep_water" then
      speed = swimming_speed
    end

  elseif command("left") and not command("right") then
    _left=true
    speed=walking_speed
    hangle = math.pi
    if map:get_ground(x,y,layer)=="deep_water" then
      speed = swimming_speed
    end
  end

  --Force the hero on a ladder if we came from the side
  if hero:test_obstacles(0,1) and test_ladder(hero) and is_ladder(map,x,y+3) then 
    --debug_print "entering ladder from the side"
    hero.on_ladder=true
  end

  --Handle movement for vertical and/or diagonal input
  if can_move_vertically==false then
    --debug_print "Trying to override the vertical movement"
    local m=hero:get_movement()
    if m then
      local a=m:get_angle()
      --debug_print (a)
      if _up==true then
        --debug_print "UP"
        --debug_print(m:get_speed(), hero:get_walking_speed())
        if _left==true or _right==true then
          --debug_print "UP-DIAGONAL"
          if hangle ~=a then 
            m:set_angle(hangle)
          end
        else
          speed = 0
        end
      elseif _down==true then
        --debug_print "DOWN"
        --debug_print (m:get_speed(), hero:get_walking_speed())
        if _left==true or _right==true then
          --debug_print "DOWN-DIAGONAL"
          m:set_angle(hangle)
          if hangle ~=a then 
            m:set_angle(hangle)
          end
        else
          --debug_print "CANCEL DOWN V-MOVE"
          speed = 0
        end
      end
    end
  end

  if speed and speed~=hero:get_walking_speed() then
    hero:set_walking_speed(speed)
  end

  --------------------
  --Update animation--
  --------------------

  speed = movement and movement:get_speed() or 0
  local sprite = hero:get_sprite("tunic")
  local direction = sprite:get_direction()
  local new_animation

  -- debug_print("state to display :"..state)
  if state == "swimming" or (state=="custom" and cstate:get_description()=="sideview_swim") then
    if speed ~= 0 then
      new_animation = "swimming_scroll"
    else
      new_animation = "stopped_swimming_scroll"
    end
  end

  if state == "lifting" then
    new_animation = "lifting_heavy"
  end

  if state == "sword loading" then

    if hero:get_ground_below() == "deep_water" then
      new_animation = "swimming_scroll_loading"
      hero:get_sprite("sword"):set_animation("sword_loading_swimming_scroll")  
    end
  end

  if state=="free" and not (hero.frozen) then
    if speed ~= 0 then
      if hero.on_ladder and test_ladder(hero) then
        new_animation = "climbing_walking"
      elseif not is_on_ground(hero) then
        if map:get_ground(x,y+4,layer)=="deep_water" then
          new_animation ="swimming_scroll"
        else
          new_animation = "jumping"
        end
      else
        new_animation = "walking"
      end
    else
      if hero.on_ladder and test_ladder(hero) then
        new_animation = "climbing_stopped"
      elseif not is_on_ground(hero) then
        if map:get_ground(x,y+4,layer)=="deep_water" then
          new_animation ="stopped_swimming_scroll"
        else
          new_animation = "jumping"
        end
      else
        new_animation = "stopped"
      end 
    end
  end
  -- debug_print(new_animation)

  if new_animation and new_animation ~= sprite:get_animation() then
    --debug_print("changing animation from \'"..sprite:get_animation().."\' to \'"..new_animation)
    sprite:set_animation(new_animation)
  end
end

--[[
  Redeclaration of the "on map changed' event to take account of the sideview mode.
  This override starts the routine which updates the gravity of the entitites for sideviews, and sets up the sprite of the hero by shifting it by 2 pixels when in sideviews.
--]]
game_meta:register_event("on_map_changed", function(game, map)

    local hero = map:get_hero() --TODO account for multiple heroes in the future
    hero.vspeed = 0
    if map:is_sideview() then
      hero.on_ladder = test_ladder(hero, -1) 
      if hero.on_ladder == true then
        hero:set_walking_speed(52)
      end
      sol.timer.start(map, 10, function()
          update_entities(map)
          return true
        end)
    else

      hero:set_walking_speed(88)
    end
  end)


hero_meta:register_event("on_state_changed", function(hero, state)
    --debug_print ("STATE CHANGED:"..state)
    local game = hero:get_game()
    local map = hero:get_map()

    if map:is_sideview() then
      if state == "free" or state == "carrying" or state == "sword loading"
      or state == "swimming" or state == "custom" then --TODO identify every applicable states
        if state == "swimming" or state =="free" and map:get_ground(hero:get_position())=="deep_water" then
          -- switch to the custom state
          hero:start_swimming()
        end
        if hero.timer == nil then
--          debug_print "create timer"
          hero.timer = sol.timer.start(hero, 10, function()
              update_hero(hero) 
              return true
            end)
        end
      elseif state == "grabbing" then -- prevent the hero from pulling things in sideviews
        hero:unfreeze()
      else
        --debug_print "Resetting sideview hero timer"
        local timer = hero.timer
        if timer~=nil then
--          debug_print"remove timer"
          timer:stop()
          hero.timer = nil
        end
      end
    else
      --debug_print "Entering top-view mode"
      local timer = hero.timer
      if timer~=nil then
--        debug_print"remove timer"
        timer:stop()
        hero.timer = nil
      end
    end
  end)