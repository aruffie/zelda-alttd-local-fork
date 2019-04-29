-- Lua script of enemy boo_buddy.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local behavior = require("enemies/lib/towards_hero")
local properties = {
  sprite = "enemies/" .. enemy:get_breed(),
  life = 1,
  damage = 1,
  normal_speed = 16,
  faster_speed = 16,
}

-- The enemy appears: set its properties.
function enemy:on_created()

  behavior:create(enemy, properties)
  
end

