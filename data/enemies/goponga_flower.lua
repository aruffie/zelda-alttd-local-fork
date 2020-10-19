----------------------------------
--
-- Goponga Flower.
--
-- Immobile enemy that repulse on sword attack received.
-- No method or events.
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
local audio_manager = require("scripts/audio_manager")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5

-- Make hero pushed back on sword attack received.
local function on_sword_attack_received()

  -- Make sure to only trigger this event once by attack.
  enemy:set_invincible()

  enemy:start_pushing_back(hero, 200, 100, sprite, nil)
  sprite:set_animation("bounce", function()
    enemy:restart()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions("ignored", {
    hookshot = 1,
    boomerang = 1,
    fire = 1,
    sword = on_sword_attack_received
  })

  -- States.
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_attacking_collision_mode("touching")
  enemy:set_traversable(false)
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  sprite:set_animation("walking")
end)
