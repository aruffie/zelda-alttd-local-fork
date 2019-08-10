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

  -- Start jumping on the current hero position and stomp down after some time.
  local target_x, target_y, _ = hero:get_position()
  enemy:start_jumping(target_x, target_y)

  -- TODO

end