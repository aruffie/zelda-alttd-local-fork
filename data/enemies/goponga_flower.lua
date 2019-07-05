-- Lua script of enemy "goponga_flower".
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local hero_is_bounce = false

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- The enemy appears: set its properties.
function enemy:on_created()

  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_traversable(false)
  enemy:set_life(1)
  enemy:set_damage(4)
  enemy:set_push_hero_on_sword(true)

  enemy:set_attack_consequence("sword", function()
      if not hero_is_bounce then
        hero_is_bounce = true
        audio_manager:play_sound("hero/bounce")
        sprite:set_animation("bounce", function()
          hero_is_bounce = false
          sprite:set_animation("walking")
        end)
      end
  end)
  enemy:set_hookshot_reaction(1)
  enemy:set_attack_consequence("boomerang", 1)
  enemy:set_attacking_collision_mode("touching")
  enemy:set_push_hero_on_sword(true)

end
