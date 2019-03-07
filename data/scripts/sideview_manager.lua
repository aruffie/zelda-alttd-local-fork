local map_meta = sol.main.get_metatable("map")
local hero_meta = sol.main.get_metatable("hero")
local game_meta = sol.main.get_metatable("game")
require("scripts/multi_events")
local walking_speed = 88
local climbing_speed= 44
local timer
local sprite
local vspeed =0
local gravity = 0.2
local max_vspeed=2.5

local movement
local is_sideview = false

function map_meta:set_sideview(sideview)
  is_sideview=sideview
end

function map_meta:is_sideview(sideview)
  return is_sideview
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
    if entity:test_obstacles(0,dy) then --we just landed.
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
    elseif entity:get_type()=="hero" and not entity.on_ladder then
      is_affected = true
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
  state = state and state or ""
  if state ~= "" then
    state = state.."_"
  end 
  if movement:get_speed() ~= speed then
    if speed>0 then
      sprite:set_animation(state.."walking")
    else
      sprite:set_animation(state.."stopped")
    end
    --print(sol.main.get_elapsed_time(), "set_speed", movement:get_speed(), " -> ", speed)
    movement:set_speed(speed) 
  end
  if movement:get_angle() ~= angle then
    --print(sol.main.get_elapsed_time(), "set_angle", movement:get_angle(), " -> ", angle)
    movement:set_angle(angle) 
    sprite:set_direction(math.floor(angle*2/math.pi))
  end
end

local function update_hero(hero, game)
  local function command(id)
    return game:is_command_pressed(id)
  end
  local x,y,layer = hero:get_position()

  --print "LOOP"
  local map = game:get_map()
  local function is_ladder(dy)
    return map:get_ground(x,y+dy, layer)=="ladder"
  end
  local speed = 0
  local angle = movement:get_angle()
  local dx, dy
  --print "COMMAND ?"
  if is_ladder(- 4) or is_ladder(3) then
    if command("up") or command("down") then
      if command("up") and (not command("down")) and is_ladder(2) then
        hero:get_sprite():set_direction(1)
        --print "RIGHT"
        angle=math.pi/2
        speed=climbing_speed
        hero.on_ladder = true

      elseif command("down") and (not command("up")) then
        hero:get_sprite():set_direction(3)
        ---print "LEFT"
        angle=1.5*math.pi
        speed=climbing_speed
      end
    end
    if hero:get_ground_below()=="ladder" then
      hero.on_ladder = true 
    else
      hero.on_ladder = false
    end
  else
    hero.on_ladder = false
  end
  if command("right") and not command("left") then
    --print "RIGHT"
    speed=walking_speed
    angle=0
  elseif command("left") and not command("right") then
    ---print "LEFT"
    angle=math.pi
    speed=walking_speed
  end
--print ("Movement speed:"..movement:get_speed()..", New speed:"..speed)
  if hero.on_ladder then
    animation = "climbing"
  elseif hero:get_state() == "carrying" then
    animation = "carrying"    
  else
    animation = ""
  end

  update_movement(hero, speed, angle, animation)
end

game_meta:register_event("on_map_changed", function(game, map)
    print "MAP JUST CHANGED"
    if map:is_sideview() then
      print "INITIALIZE GRAVITY"
      sol.timer.start(map, 10, function()
          update_entities(map)
          return true
        end)
    end
  end)


hero_meta:register_event("on_state_changed", function(hero, state)
    --print ("STATE CHANGED:"..state)
    local game = hero:get_game()
    if movement then 
      movement:stop()
      movement = nil
    end
    if timer then
      timer:stop()
      timer = nil
    end

    local map = hero:get_map()
    if is_sideview then
      sprite=hero:get_sprite()
      if state == "free" or state == "carrying" then
        movement=sol.movement.create("straight")
        movement:set_angle(-1)
        movement:set_speed(0)
        movement:start(hero)
        timer = sol.timer.start(hero, 10, function()
            update_hero(hero, game) 
            return true
          end)
      end
    end
  end)