-- Lua script of enemy mini_thwomp.
-- This script is executed every time an enemy with this model is created.

local enemy = ...
local behavior = require("enemies/lib/thwomp_crush")

local properties = {
  sprite = "enemies/" .. enemy:get_breed(),
  life = 8,
  damage = 4,
  hurt_style = "monster",
  push_hero_on_sword = true,
  crash_sound = "items/bomb_drop",
  faster_speed = 200,
  outer_detection_range = 8,
}

behavior:create(enemy, properties)
