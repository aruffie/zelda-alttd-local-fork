local map_meta = sol.main.get_metatable("map")
local hero_meta = sol.main.get_metatable("hero")
require("scripts/multi_events")
local __hero

local movement=sol.movement.create("straight")
movement:set_speed(88)

function map_meta:set_sideview(sideview)
  self.sideview=sideview
end

function map_meta:is_sideview(sideview)
  return self.sideview or false
end


local moving
local already_moving

hero_meta:register_event("on_created", function(hero)
  __hero = hero
end)

local function update_hero()
  --print "LOOP"
  local game = __hero:get_game()
    --print "COMMAND ?"
    if game:is_command_pressed("down")then
    --  print "DOWN"
      movement:set_angle(3*math.pi/2)
      moving = true
    elseif game:is_command_pressed("left") then
     -- print "LEFT"
      movement:set_angle(math.pi)
      moving = true
    elseif game:is_command_pressed("right") then
     -- print "RIGHT"
      movement:set_angle(math.pi*2)
      moving = true
    else --reset movement
      moving = false

      if already_moving then
        already_moving = false
        print "STOP"
        movement:stop()
      end
    end
    if moving and not already_moving then
      print "MOVE"
      already_moving = true
      movement:start(__hero)
      __hero:unfreeze()

    end

    local m = __hero:get_movement()
    local speed = m and m:get_speed() or 0
    print("current speed: "..speed)
  return true
end
       
hero_meta:register_event("on_state_changed", function(hero, state)
  print ("STATE CHANGED:"..state)
  local map = hero:get_map()
  if map.is_sideview and map:is_sideview() then
    print "START TIMER"
    if state == "free"  then
       sol.timer.start(hero, 10, update_hero)
    end
  end
end)