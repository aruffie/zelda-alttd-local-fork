-- Lua script of enemy face_lamp.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local behavior = require("enemies/lib/fire_breathing_statue")

local properties = {
  sprite = "enemies/face_lamp/face_lamp",
  projectile_breed = "eyegore_statue/eyegore_statue_fireball",
  projectile_sound = "enemies/face_lamp",
}

behavior:create(enemy, properties)
