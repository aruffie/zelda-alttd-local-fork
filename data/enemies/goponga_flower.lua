-- Lua script of enemy goponga flower.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
local audio_manager = require("scripts/audio_manager")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local is_hero_pushable = true

-- Make hero retreat on sword attack received
function on_sword_attack_received()

  if is_hero_pushable then
    is_hero_pushable = false
    enemy:start_pushing_back(hero, 200, 100)
    sprite:set_animation("bounce", function()
      sprite:set_animation("walking")
    end)
    sol.timer.start(map, 300, function() -- Only push once even if the sword still collide at following frames.
      is_hero_pushable = true
    end)
  end
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
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
