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
local climbing_speed= 44
local gravity = 0.05
local max_vspeed=2.3

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
  self.sideview=enabled
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
  The core function of the side views : 
  it applies a semi-realistic gravity to the given entity, and resets the vertical speed if :
    we reached a solid obstacle,
    we laanded on top of a ladder
    
    Parameter : entity, the entity to apply the gravity on.
--]]

local function apply_gravity(entity)
  --Apply gravity
  local vspeed = entity.vspeed or 0
  vspeed = math.min(vspeed+gravity, max_vspeed)

  local x,y=entity:get_position()
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
      if entity:get_type() == "pickable" or entity:get_type()=="carried_object" then
        is_affected = true
      elseif entity:get_type()=="hero" then
        if entity.on_ladder then
          is_affected = false
        else
          is_affected = true
        end
      else
        is_affected = false
      end
      -- Make entity fall.
      if has_property or is_affected then
        apply_gravity(entity)
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
  Also updates the sprite of the hero.
  
  Parameters:
    hero : the hero object.
    speed : the new speed of the movement.
    angle : the new angle of the movement.
    state : the prefix of the animation to apply on the sprite (nil means use no prefix)
--]]

local function update_movement(hero, speed, angle, state)
  local movement = hero.movement
  local sprite = hero:get_sprite()
  state = state and state or ""
  local prefix = ""
  if state ~= "" then
    prefix = state.."_" 
  end
  local new_animation
  --[[
            | stopped(speed = 0)  carry    walk
  on ground | stopped             carry    walk  
  falling   [ stopped             carry    jump
  --]]
  if speed == 0 then
    new_animation = prefix.."stopped"  
    if state == "lifting" then
      new_animation = "lifting_heavy"
    elseif  state == "" and not is_on_ground(hero) then
      new_animation = "jumping"
    end
  else 
    if state == "lifting" then
      new_animation = "lifting_heavy"
    elseif state == "climbing" then
      new_animation = "climbing_walking"
    elseif is_on_ground(hero) then
      if state == "carrying" then
        new_animation = "carrying_walking"
      else
        new_animation = "walking"
      end
    else
      if state == "carrying" then
        new_animation = "carrying_stopped"
      else
        new_animation = "jumping"
      end
    end
  end
  --print(new_animation)

  if movement:get_speed() ~= speed then
    --print(sol.main.get_elapsed_time(), "set_speed", movement:get_speed(), " -> ", speed)
    movement:set_speed(speed) 
  end

  if movement:get_angle() ~= angle then
    --print(sol.main.get_elapsed_time(), "set_angle", movement:get_angle(), " -> ", angle)
    movement:set_angle(angle) 
    sprite:set_direction(math.floor(angle*2/math.pi))
  end
  if new_animation ~= sprite:get_animation() then
    sprite:set_animation(new_animation)
  end
end

--[[
  TODO find a better explanation for this core function

  Updates the internal state of the hero, by reading the currently pressed arrow keys commands.
  This is also where it get attached to the ladder if it is against one by pressing
  
  Parameter : hero, the hero object.
--]]

local function update_hero(hero)
  local movement = hero.movement
  local game = hero:get_game()

  local function command(id)
    return game:is_command_pressed(id)
  end

  local x,y,layer = hero:get_position()
  local map = game:get_map()
  local speed = 0
  local angle = movement:get_angle()
  local dx, dy
  local animation=""

  if command("up") and not command("down") then
    angle=math.pi/2
    if test_ladder(hero) then
      hero.on_ladder = true
      speed=climbing_speed
    end
  elseif command("down") and not command("up") then
    ---print "LEFT"
    angle=1.5*math.pi
    if test_ladder(hero) or is_ladder(map, x, y+3) then
      hero.on_ladder = true
      speed=climbing_speed
    end
  end

  if not (test_ladder(hero) or is_ladder(map, x, y+3)) then
    hero.on_ladder = false
  end

  if command("right") and not command("left") then
    speed=walking_speed
    angle=0
  elseif command("left") and not command("right") then
    angle=math.pi
    speed=walking_speed
  end

  if hero:test_obstacles(0,1) and test_ladder(hero, -1) and is_ladder(map,x,y+3) then 
    hero.on_ladder=true
  end

--print ("Movement speed:"..movement:get_speed()..", New speed:"..speed)
  if hero.on_ladder and test_ladder(hero, -1) then
    animation = "climbing"
  elseif hero:get_state() == "carrying" then
    animation = "carrying"    
  elseif hero:get_state() == "lifting" then
    animation = "lifting"
  else
    animation = ""
  end

  update_movement(hero, speed, angle, animation)
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

hero_meta:register_event("on_state_changed", function(hero, state)
    --print ("STATE CHANGED:"..state)
    local game = hero:get_game()
    local map = hero:get_map()
    local movement = hero.movement
    if movement then
      movement:stop()
      movement = nil
    end
    local timer = hero.timer
    if timer then
      timer:stop()
      timer = nil
    end

    if map:is_sideview() then
      if state == "free" or state == "carrying" then
        local movement=sol.movement.create("straight")
        movement:set_angle(-1)
        movement:set_speed(0)
        movement:start(hero)
        hero.movement = movement
        timer = sol.timer.start(hero, 10, function()
            update_hero(hero) 
            return true
          end)
      end
    end
  end)