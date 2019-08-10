-- Lua script of enemy blue stalfos.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/stalfos").apply(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

-- Event triggered when the enemy is close enough to the hero.
function enemy:on_attacking()

  -- Start jumping away from the hero.
  local enemy_x, enemy_y, _ = enemy:get_position()
  local hero_x, hero_y, _ = hero:get_position()
  enemy:start_jumping(enemy_x * 2.0 - hero_x, enemy_y * 2.0 - hero_y)

  -- TODO

end