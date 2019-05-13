-- Lua script of enemy stalfos.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())

-- The enemy appears: set its properties.
function enemy:on_created()
  
  enemy:set_life(3)
  enemy:set_damage(2)

end

