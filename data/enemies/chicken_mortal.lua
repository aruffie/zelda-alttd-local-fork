-- Lua script of enemy chicken mortal.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local map = enemy:get_map()

-- The enemy appears: set its properties.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(10)
  enemy:set_damage(2)
  enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:set_hurt_style("monster")
  
end)

enemy:register_event("on_movement_changed", function(enemy, movement)

  local direction4 = movement:get_direction4()
  local sprite = enemy:get_sprite()
  sprite:set_direction(direction4)
  
end)

-- The enemy was stopped for some reason and should restart.
enemy:register_event("on_restarted", function(enemy)

  local movement = sol.movement.create("random")
  movement:set_speed(64)
  movement:start(enemy)
  enemy:get_sprite():set_animation("running")
  
end)