-- Lua script of enemy mini_thwomp.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local behavior = require("enemies/lib/thwomp_crush")
local properties = {
  sprite = "enemies/" .. enemy:get_breed(),
  damage = 2,
  hurt_style = "monster",
  push_hero_on_sword = true,
  is_walkable = true,
  crash_sound = "items/bomb_explode",
  outer_detection_range = 16
}

-- The enemy appears: set its properties.
enemy:register_event("on_created", function(enemy)
  
  behavior:create(enemy, properties)
  
end)