-- Lua script of enemy face_lamp.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local behavior = require("enemies/lib/fire_breathing_statue")
local properties = {
  sprite = "enemies/" .. enemy:get_breed(),
  projectile_breed = "fireball_small_triple_red",
  projectile_sound = "enemies/face_lamp",
}

-- Event called when the enemy is initialized.
function enemy:on_created()

  behavior:create(enemy, properties)
  
end

