--[[
Sideview manager

This script implements gravity and interaction of the hero with ladders, which are used in sideview maps.

To initialize, just require it in a game setup script, like features.lua, 
   then call map:set_sidewiew(true) in the on_started event of each map you want to be in sideview mode.
   
If you need to make things jump like the hero when he uses the feather, then simply do <your_entity>.vspeed=<some_negative_number>, then the gravity will do the rest.

In the same way, you can make any entity be affected by gravity by adding "has_gravity" in it's custom properties.

--]]

local map_meta = sol.main.get_metatable("map")
local hero_meta = sol.main.get_metatable("hero")
local game_meta = sol.main.get_metatable("game")
require("scripts/multi_events")
local walking_speed = 88
local climbing_speed= 44
local timer 
local gravity = 0.2
local max_vspeed=2.5
local movement

--Returns whether the ground at given XY coordinates is a ladder.
local function is_ladder(map, x,y, layer)
  layer=layer or 0
  return map:get_ground(x,y, layer)=="ladder"
end

--[[
  Returns whether the ground under the top-middle or the bottom-middle points of the bounding box of a given entity is a ladder.
--]]
local function test_ladder(entity)
  local map=entity:get_map()
  local x,y,w,h = entity:get_bounding_box() 
  return is_ladder(map, x+w/2, y) or is_ladder(map, x+w/2, y+h-1)
end

local function apply_gravity(entity)
  --Apply gravity
  local vspeed = entity.vspeed or 0
  if vspeed<=max_vspeed then
    vspeed = vspeed+gravity
  end
  local x,y=entity:get_position()
  local dy=0
  while dy<=vspeed do 
    if entity:test_obstacles(0,dy) or 
    entity:get_type()=="hero" and
    (not test_ladder(entity) and is_ladder(entity:get_map(), x, y+3+dy)) then --we just landed.
      vspeed = 0
      --print("Ground hit. Last valid position:"..y+dy)
      break
    end
    dy=dy+0.1
  end

  entity:set_position(x,y+dy)
  entity.vspeed = vspeed   
end


local function update_entities(map)    -- Allow other entities to fall with the gravity timer.
  -- Pickables always fall by default. Entities with "g_" prefix or defining
  -- the custom property "sidemap_gravity" different from nil will fall.
  for entity in map:get_entities() do
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

local function update_movement(hero, speed, angle, state)
  local sprite = hero:get_sprite()
  state = state and state or ""
  if state ~= "" then
    state = state.."_"
  end

  if speed>0 then
    new_animation=state.."walking"
  else
    new_animation=state.."stopped"
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

local function update_hero(hero)
  
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

  if command("up") and (not command("down")) then
    angle=math.pi/2
    if test_ladder(hero) then
      hero.on_ladder = true
      speed=climbing_speed
    end
  elseif command("down") and (not command("up")) then
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
  else
    animation = ""
  end

  update_movement(hero, speed, angle, animation)
end

game_meta:register_event("on_map_changed", function(game, map)
    if map.is_sideview then
      map:get_hero().on_ladder = test_ladder(map:get_hero(), -1) 
      sol.timer.start(map, 10, function()
          update_entities(map)
          return true
        end)
    end
  end)


hero_meta:register_event("on_state_changed", function(hero, state)
    --print ("STATE CHANGED:"..state)
    local game = hero:get_game()
    local map = hero:get_map()
    if movement then
      movement:stop()
      movement = nil
    end
    if timer then
      timer:stop()
      timer = nil
    end

    if map.is_sideview then
      if state == "free" or state == "carrying" then
        movement=sol.movement.create("straight")
        movement:set_angle(-1)
        movement:set_speed(0)
        movement:start(hero)
        timer = sol.timer.start(hero, 10, function()
            update_hero(hero) 
            return true
          end)
      end
    end
  end)