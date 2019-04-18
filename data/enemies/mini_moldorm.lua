-- Lua script of enemy "small moldorm".
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement

-- Event called when the enemy is initialized.
function enemy:on_created()

  sprite = enemy:create_sprite("enemies/mini_moldorm/" .. enemy:get_breed())
  enemy:set_traversable(false)
  enemy:set_life(1)
  enemy:set_damage(1)

end