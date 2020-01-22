-- Lua script of enemy dog.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local map = enemy:get_map()
local angry = false
local sprite
local walking_timer

-- The enemy appears: set its properties.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(10000)
  enemy:set_damage(2)
  enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:set_hurt_style("monster")
  sprite = enemy:get_sprite()
  
  function sprite:on_animation_finished(animation)
    if animation == "prepare_waiting" then
      sprite:set_animation("waiting")
      sol.timer.start(enemy, 1000, function()
        sprite:set_animation("prepare_walking")
      end)
    elseif animation == "prepare_walking" then
      enemy:go_random()
    end
  end
  
end)

-- The enemy was stopped for some reason and should restart.
enemy:register_event("on_restarted", function(enemy)

  if angry then
    enemy:go_angry()
  else
    enemy:go_random()
  end
   
end)

enemy:register_event("on_movement_changed", function(enemy, movement)

  local direction4 = movement:get_direction4()
  sprite:set_direction(direction4)
  
end)

enemy:register_event("on_obstacle_reached", function(enemy)

  if walking_timer then
    walking_timer:stop()
  end
  enemy:go_random()

end)

function enemy:launch_waiting()
  
  local movement = enemy:get_movement()
  if movement then
    movement:stop()
  end
  sprite:set_animation("prepare_waiting")
  
end

function enemy:go_random()

  enemy:set_can_attack(false)
  angry = false
  sprite:set_animation("walking")
  local movement = sol.movement.create("random")
  movement:set_speed(32)
  movement:start(enemy)
  walking_timer = sol.timer.start(enemy, 5000, function()
    enemy:launch_waiting()
  end)
  
end

function enemy:go_angry()

  local game = map:get_game()
  local hero = game:get_hero()
  local direction4 = enemy:get_direction4_to(hero)
  enemy:set_can_attack(true)
  sprite:set_direction(direction4)
  sprite:set_animation("angry")
  local movement = sol.movement.create("target")
  movement:set_speed(96)
  movement:start(enemy)
  function movement:on_finished()
    enemy:go_random()
  end
    
end

enemy:register_event("on_hurt", function(enemy)

  angry = true

end)