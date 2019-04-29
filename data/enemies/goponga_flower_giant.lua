-- Lua script of enemy giant_goponga_flower.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement

-- The enemy appears: set its properties.
function enemy:on_created()

  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_traversable(false)
  enemy:set_life(1)
  enemy:set_damage(1)
  enemy:set_invincible(true)
  enemy:set_size(32, 32)
  enemy:set_origin(16, 29)
  enemy:set_attacking_collision_mode("touching")

end