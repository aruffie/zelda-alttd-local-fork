-- Lua script of enemy genie.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement
local bottle
local bottle_sprite

-- Event called when the enemy is initialized.
function enemy:on_created()

  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(1)
  enemy:set_damage(1)
  enemy:set_hurt_style("boss")
  enemy:set_visible(false)

end

-- Event called when the enemy should start or restart its movements.
function enemy:on_restarted()

end
