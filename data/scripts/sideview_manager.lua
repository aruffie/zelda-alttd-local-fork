--[[
Sideview manager

This script implements gravity and interaction of the hero with ladders, which are used in sideview maps.

To initialize, just require it in a game setup script, like features.lua, 
   then call map:set_sidewiew(true) in the on_started event of each map you want to be in sideview mode.
   
If you need to make things jump like the hero when he uses the feather, then simply do <your_entity>.vspeed=<some_negative_number>, then the gravity will do the rest.

In the same way, you can make any entity be affected by gravity by adding "has_gravity" in its custom properties.


TODO check these points:
- [ ] Désactiver l'attaque tournoyante quand on monte à l'échelle
- [ ] Bug de vitesse quand on marche sur les échelles en concentrant l'épée 
- [en cours] QUand Link marche sur les échelles y a un petit espace entre lui et l'échelle. Ca donne l'impression qu'il vole
-- [X] Décaler le sprite de Link
-- [ ] Décaler le sprite des pots --> Fonctionne mais le pot est dans un état indéfini entre le moment ou on commence à la soulever et le moment ou il est au dessus de la têde du héros 
-- [ ] Décaler le sprite des items en cours d'utilisation.

- [ ] Chez moi je narrive pas à descendre sur l'échelle isolée
- [ ] Quand Link est au dessus d'un pot et qu'il le ramasse, il descend (à cause dela gravité) un peu trop tot je trouve.
- [nécéssite de changer le comportement des cillosions et/ou les hitbox] si je ramasse un pot et que je suis à cheval sur un autre pot, je sais pas si y a moyen de le faire descendre quand meme dans certains cas car on dirait qu'il vole un peu
--]]

local map_meta = sol.main.get_metatable("map")
local hero_meta = sol.main.get_metatable("hero")
local game_meta = sol.main.get_metatable("game")
require("scripts/multi_events")
local walking_speed = 88
local swimming_speed = 66
local climbing_speed = 44
local gravity = 0.2
local max_vspeed=2

--[[
  Returns whether the ground at given XY coordinates is a ladder.
  This is actually a shortcut to avoid multiples instances of "map:get_ground(x,y, layer)=="ladder" in tests.
  Parameters : 
   map, the map object
   x,y, the corrdinates of the point to test
--]]
local function is_ladder(map, x,y, layer)
  layer=layer or 0
  return map:get_ground(x,y, layer)=="ladder"
end

--[[
  Sets whether we are in sideview mode in the current map.
  Parameter: enabled (boolean or nil).
--]]
function map_meta:set_sideview(enabled)
  self.sideview=enabled or false
end

--[[
  Returns whether the current map is in sideview mode.
--]]
function map_meta:is_sideview()
  return self.sideview or false
end

--[[
  Sets the vertical speed on the entity, in pixels/frame.
  Parameter: vspeed, the new vertical speed.
--]]
function map_meta:set_vertical_speed(entity, vspeed)
  entity.vspeed = vspeed
end

--[[
  Returns whether the current vertical speed of the entity, in pixels/frame.
--]]
function map_meta:get_vertical_speed(entity)
  return entity.vspeed or 0
end

local debug_respawn_surface = sol.surface.create(16,16)
debug_respawn_surface:fill_color({255,127,0})

map_meta:register_event("on_draw", function(map, dst_surface)
    -- if map:is_sideview() then
    local x,y = map:get_camera():get_position()
    local xx,yy=map:get_hero():get_solid_ground_position()
    debug_respawn_surface:draw(dst_surface, xx-x-8, yy-y-13)
    --end
  end)
map_meta:register_event("on_opening_transition_finished", function(map, dst_surface)
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

--[[
  Updated version of the core function of the side views : 
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
  if vspeed >= 0 then
    if entity:test_obstacles(0,1) or 
    entity.on_ladder or
    test_ladder(entity)==false and is_ladder(entity:get_map(), x, y+3) then --we are on an obstacle, reset speed.
      if entity:get_type()=="hero" and y+2<h and entity:test_obstacles(0,1) and map:get_ground(x,y+3,layer)=="wall" then
        entity:save_solid_ground(x,y,layer)
      end
      entity.vspeed = nil
      return false
    end
    entity:set_position(x,y+1)
  else
    if not entity:test_obstacles(0,-1) then
      entity:set_position(x,y-1)
    end
  end
  if map:get_ground(x,y,layer)=="deep_water" then
    vspeed = math.min(vspeed+gravity/3, 0.2)
  else
    vspeed = math.min(vspeed+gravity, max_vspeed)
  end
  entity.vspeed = vspeed
  return math.min(math.floor(10/math.abs(vspeed)), 100)
end

--[[
  The previous version of the core function of the side views : 
  it applies a semi-realistic gravity to the given entity, and resets the vertical speed if :
    we reached a solid obstacle,
    we laanded on top of a ladder
    
    Parameter : entity, the entity to apply the gravity on.
--]]

local function apply_gravity_old(entity)
  --Apply gravity
  local vspeed = entity.vspeed or 0
  local x,y,layer = entity:get_position()

  local map = entity:get_map()
  local w,h = map:get_size()
  if map:get_ground(x,y,layer)=="deep_water" then
    vspeed = math.min(vspeed+gravity/2, 0.85)
  else
    vspeed = math.min(vspeed+gravity, max_vspeed)
  end
  local dy=0
  --TODO : push the entity out of any obstacle it could be stuck in.
  while dy<=vspeed do 
    if entity:test_obstacles(0,dy) or 
    test_ladder(entity)==false and is_ladder(entity:get_map(), x, y+3+dy) then --we are on an obstacle, reset speed.
      vspeed = 0
      break
    end
    dy=dy+0.1
  end

  entity:set_position(x,y+dy)
  entity.vspeed = vspeed   
end

--[[
-- Loops through every active entity and checks if it should be affected by gravity, calling apply_gravity if applicable.
  Pickables and the hero are always affected.
  Other entities will not be affeted unless they have defined a custom property called "sidemap_gravity".
  
  Parameter : map, the map object.
--]]
local function update_entities(map)  
  for entity in map:get_entities() do
    if entity:is_enabled() then
      -- Check entitites that can fall.
      local is_affected
      local has_property = entity:get_property("has_gravity")
      if entity:get_type() == "pickable" or entity:get_type()=="carried_object" or entity:get_type() =="hero" then
        is_affected = true
      else
        is_affected = false
      end
      -- Make entity fall.
      if has_property or is_affected then
        --start gravity effect timer loop
        if entity.gravity_timer==nil then
          entity.gravity_timer=sol.timer.start(entity, 10, function()
              local new_delay = apply_gravity(entity)
              if not new_delay then
                entity.gravity_timer=nil
              end
              --print("new delay"..new_delay)
              return new_delay
            end)
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

--[[
  Updates the movement of the hero, after performing checks in order to avoid a bug based on setting them every frame.
  
  Parameters:
    hero : the hero object.
    speed : the new speed of the movement.
    angle : the new angle of the movement.
--]]

local function update_movement(hero, speed, angle, state)
  local movement = hero.movement
  --print(new_animation)

  if movement and movement:get_speed() ~= speed then
    --print(sol.main.get_elapsed_time(), "set_speed", movement:get_speed(), " -> ", speed)
    movement:set_speed(speed) 
  end

  if movement and movement:get_angle() ~= angle then
    --print(sol.main.get_elapsed_time(), "set_angle", movement:get_angle(), " -> ", angle)
    movement:set_angle(angle) 
  end
end


hero_meta:register_event("on_movement_changed", function(hero, movement)
    --print("New movement: speed" ..movement:get_speed().. ", angle:"..movement:get_angle()*180/math.pi)
  end)

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
  Updates the sprite animation of the given hero.
  
  Parameters:
    hero : the hero object.
--]]

local function update_animation(hero, direction)
  local state = hero:get_state()
  local map = hero:get_map()
  local movement = hero.movement
  local x,y,layer = hero:get_position()
  local sprite = hero:get_sprite("tunic")
  local prefix = ""
  if state ~= "free" then
    prefix = state.."_" 
  end
  local new_animation
  --[[
            | stopped(speed = 0)  carry    walk
  on ground | stopped             carry    walk  
  falling   [ stopped             carry    jump
  --]]
  -- print("state to display :"..state)
  if state == "swimming" then
    if movement:get_speed() ~= 0 then
      new_animation = "swimming_scroll"
    else
      new_animation = "stopped_swimming_scroll"
    end
  end

  if state == "lifting" then
    new_animation = "lifting_heavy"
  end

  if state == "sword loading" then
    if movement:get_speed() ~= 0 then
      new_animation = "sword_loading_walking"
      hero:get_sprite("sword"):set_animation("sword_loading_walking")
    else
      new_animation = "sword_loading_stopped"
      hero:get_sprite("sword"):set_animation("sword_loading_stopped")    
    end
    if hero:get_ground_below() == "deep_water" then
      new_animation = "swimming_scroll_loading"
      hero:get_sprite("sword"):set_animation("sword_loading_swimming_scroll")  
    end
  end

  if state=="free" then
    if movement:get_speed() == 0 then
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
    else
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
    end
  end
  -- print(new_animation)

  if new_animation and new_animation ~= sprite:get_animation() then
--    sprite:set_frame(0)
    --print("changing animation from \'"..sprite:get_animation().."\' to \'"..new_animation)
    sprite:set_animation(new_animation)
  end

  if state ~= "sword loading" and state ~="sword tapping" and state ~= "sword swinging" then
    sprite:set_direction(direction)
  end
end

--[[
  TODO find a better explanation for this core function

  Updates the internal state of the hero, by reading the currently pressed arrow keys commands.
  This is also where it get attached to the ladder if it is against one by pressing
  
  Parameter : hero, the hero object.
--]]

local function update_hero(hero)
  local movement = hero.movement or hero:get_movement()
  local game = hero:get_game()

  local function command(id)
    return game:is_command_pressed(id)
  end

  local x,y,layer = hero:get_position()
  local map = game:get_map()
  local speed = 0
  local angle = movement and movement:get_angle() or 0
  local direction = hero:get_sprite():get_direction()
  local dx=0
  local dy=0
  local animation=""

  --TODO enhance the movement angle calculation.
  if command("up") and not command("down") then
    direction=1
    if test_ladder(hero) then
      dy = 1
      hero.on_ladder = true
      speed=climbing_speed
    elseif map:get_ground(x,y,layer)=="deep_water" then 
      dy = 1
      speed = swimming_speed
    end
  elseif command("down") and not command("up") then
    ---print "LEFT"
    direction=3
    if map:get_ground(x,y+3, layer) =="deep_water" then
      dy=-1
      speed = swimming_speed
    elseif test_ladder(hero) or is_ladder(map, x, y+3, layer) then
      dy=-1
      hero.on_ladder = true
      speed=climbing_speed
    end
  end

  if not (test_ladder(hero) or is_ladder(map, x, y+3)) then
    hero.on_ladder = false
  end

  if command("right") and not command("left") then
    direction = 0
    dx=1
    speed=walking_speed
    if hero:get_ground_below()=="deep_water" then
      speed = swimming_speed
    end

  elseif command("left") and not command("right") then
    dx=-1
    direction=2
    speed=walking_speed
    if hero:get_ground_below()=="deep_water" then
      speed = swimming_speed
    end
  end

  if hero:test_obstacles(0,1) and test_ladder(hero) and is_ladder(map,x,y+3) then 
    hero.on_ladder=true
  end

  update_movement(hero, speed, math.atan2(dy,dx)%(2*math.pi))
  update_animation(hero, direction)
end

--[[
  Draws the sprites of the hero at a given offset from it's actual position, as well as the ones from any entity attached to it, if applicable.
  Also allows to skip drawing the shadow if needed, which is the case in sideview mode.
  
  TODO check for any missing attached entity and add it here.
--]]
local function draw_hero(hero, has_shadow, offset)
  local x,y = hero:get_position()
  local map = hero:get_map()

--  print "DRAW HERO"
  for set, sprite in hero:get_sprites() do
    if set~="shadow" or has_shadow then
--      print ("Displaying sprite element : "..set..' with animation: '..sprite:get_animation())
      map:draw_visual(sprite, x, y+offset)
    end
  end
  for i, carried_entity in map:get_entities_by_type("carried_object") do
    --print "carried entity found"
  end
  local carried_object=hero:get_carried_object()
  if carried_object then
    --print "DRAW POT"
    for set, sprite in carried_object:get_sprites() do
--      print (set)
      if set~="shadow" or has_shadow then
        map:draw_visual(sprite, x,y-16+offset)
      end
    end
  end
end

--[[
  Redeclaration of the "on map changed' event to take account of the sideview mode.
  This override completely refefines how the hero is drawed by setting the draw_override, as well as starting the routine which updates the gravity of the entitites for sideviews.
--]]
game_meta:register_event("on_map_changed", function(game, map)

    local hero = map:get_hero() --TODO account for multiple heroes
    local has_shadow=true
    local v_offset = 0
    local timer = hero.timer
    if timer then
      timer:stop()
      timer = nil
    end
    if map:is_sideview() then
      has_shadow = false
      v_offset = 2
      hero.on_ladder = test_ladder(map:get_hero(), -1) 
      hero.vspeeed = 0
      sol.timer.start(map, 10, function()
          update_entities(map)
          return true
        end)
    end

    hero:set_draw_override(function()  
        draw_hero(hero, has_shadow, v_offset)
      end)
  end)

hero_meta:register_event("on_state_changing", function(hero, state, new_state)
    local map = hero:get_map()
    --print ("changing state from ".. state .." to ".. new_state)
    if state =="sword loading" and new_state == "swimming" then
      if map:is_sideview() then
        hero:start_attack_loading()
      end
    end
  end)

hero_meta:register_event("on_state_changed", function(hero, state)
    --print ("STATE CHANGED:"..state)
    local game = hero:get_game()
    local map = hero:get_map()
    local movement = hero.movement

    if map:is_sideview() then
      if state == "free"
      or      state == "carrying" 
      or      state == "sword loading"
      or      state == "swimming"
      then --TODO indentify every applisacle states
        local movement=sol.movement.create("straight")
        movement:set_angle(-1)
        movement:set_speed(0)
        movement:start(hero)
        hero.movement = movement
        hero.timer = sol.timer.start(hero, 10, function()
            update_hero(hero) 
            return true
          end)
      elseif state == "grabbing" then -- prevent the hero from pulling things in sideviews
        hero:unfreeze()
      else
        if movement then
          movement:stop()
          hero.movement = nil
        end
        local timer = hero.timer
        if timer then
          timer:stop()
          timer = nil
        end
      end
    else
      if movement then
        movement:stop()
        hero.movement = nil
      end
      local timer = hero.timer
      if timer then
        timer:stop()
        timer = nil
      end
    end
  end)