local map_meta = sol.main.get_metatable("map")
local hero_meta = sol.main.get_metatable("hero")
require("scripts/multi_events")
local walking_speed = 88
local timer
local sprite
local vspeed =0
local gravity = 0.1
local max_vspeed=2.5

local movement=sol.movement.create("straight")
movement:set_angle(-1)
movement:set_speed(0)
local is_sideview = false

function map_meta:set_sideview(sideview)
  is_sideview=sideview
end

function map_meta:is_sideview(sideview)
  return is_sideview
end

--[[
function movement:on_changed()
  print ("CHANGE IN MOVEMENT DETECTED", "New angle: "..movement:get_angle(), "New speed: "..movement:get_speed())
end
--]]
--[[
function hero_meta:on_position_changed()
  print"MOVE DETECTED"
end
--]]
function apply_gravity(entity)
    --Apply gravity
  local vspeed = entity.vspeed or 0
  vspeed = vspeed+gravity
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

local function update_hero(hero, game)
  --print "LOOP"
  local speed = 0
  local angle = movement:get_angle()
  --print "COMMAND ?"
  if game:is_command_pressed("right") and not game:is_command_pressed("left") then
    --print "RIGHT"
    speed=walking_speed
    angle=0
  elseif game:is_command_pressed("left") and not game:is_command_pressed("right") then
    ---print "LEFT"
    angle=math.pi
    speed=walking_speed
    --elseif game:is_command_pressed("down") then
    --  print "DOWN"

    --  movement:set_angle(3*math.pi/2)
  else --reset movement
    --print "STOP"
  end
  --print ("Movement speed:"..movement:get_speed()..", New speed:"..speed)
  if movement:get_speed() ~= speed then
    if speed>0 then

      sprite:set_animation("walking")
    else
      sprite:set_animation("stopped")
    end
    --print(sol.main.get_elapsed_time(), "set_speed", movement:get_speed(), " -> ", speed)
    movement:set_speed(speed) 
  end
  if movement:get_angle() ~= angle then
    --print(sol.main.get_elapsed_time(), "set_angle", movement:get_angle(), " -> ", angle)
    movement:set_angle(angle) 
    sprite:set_direction(math.floor(angle*2/math.pi))
  end

  --for debug only
  local m = hero:get_movement()
  local debug_speed = m and m:get_speed() or 0
  --print("current speed: "..debug_speed)
  
  apply_gravity(hero)
end

hero_meta:register_event("on_state_changed", function(hero, state)
    --print ("STATE CHANGED:"..state)
    local game = hero:get_game()
    
    if timer then
      print "STOP TIMER"
      timer:stop()
      timer = nil
    end

    local map = hero:get_map()
    if is_sideview then
      sprite=hero:get_sprite()     
      if state == "free"  then

        movement:start(hero)
        print "START TIMER"
        timer = sol.timer.start(hero, 10, function()
            update_hero(hero, game) 
            return true
          end)
      end
    end
  end)