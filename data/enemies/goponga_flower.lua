-- Lua script of enemy "goponga_flower".
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite

-- The enemy appears: set its properties.
function enemy:on_created()

  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_traversable(false)
  enemy:set_life(1)
  enemy:set_damage(4)
  enemy:set_attack_consequence("sword", function()
      sprite:set_animation("bounce", function()
          sprite:set_animation("walking")
      end)
  end)
  enemy:set_hookshot_reaction(1)
  enemy:set_attack_consequence("boomerang", 1)
  enemy:set_attacking_collision_mode("touching")

end
