----------------------------------
--
-- Facade.
--
-- Immobile enemy that throws entity on the map to the hero, then .
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5

-- Configuration variables
local between_throws_duration = 500

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(5)
  enemy:set_size(96, 72)
  enemy:set_origin(48, 36)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions({
    arrow = "ignored",
    boomerang = "ignored",
    explosion = "ignored",
    sword = "ignored",
    thrown_item = "ignored",
    fire = "ignored",
    jump_on = "ignored",
    hammer = "ignored",
    hookshot = "ignored",
    magic_powder = "ignored",
    shield = "ignored",
    thrust = "ignored"
  })

  -- States.
  enemy:set_damage(0)
  enemy:set_can_attack(false)
end)
