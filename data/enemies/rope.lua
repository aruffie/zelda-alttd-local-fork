-- Lua script of enemy gibdo.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
local common_actions = require("enemies/lib/common_actions")
require("scripts/multi_events")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())

-- Initialization.
enemy:register_event("on_created", function(enemy)

  common_actions.learn(enemy, sprite)
  enemy:set_life(6)
end

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_attack_consequence("thrown_item", 1)
  enemy:set_attack_consequence("hookshot", 1)
  enemy:set_attack_consequence("sword", 1)
  enemy:set_attack_consequence("arrow", 1)
  enemy:set_attack_consequence("boomerang", 1)
  enemy:set_attack_consequence("explosion", 1)
  enemy:set_hammer_reaction(1)
  enemy:set_fire_reaction(1)

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(1)
end
