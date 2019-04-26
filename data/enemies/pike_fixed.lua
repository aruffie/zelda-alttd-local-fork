-- Lua script of enemy "pike fixed".
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...

-- The enemy appears: set its properties.
function enemy:on_created()

  enemy:set_life(1)
  enemy:set_damage(4)
  enemy:create_sprite("enemies/pike_fixed")
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:set_can_hurt_hero_running(true)
  enemy:set_invincible()
  
end

