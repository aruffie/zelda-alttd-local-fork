-- Lua script of enemy mini_moldorm.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
local common_actions = require("enemies/lib/common_actions")
require("scripts/multi_events")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local head_sprite, body_sprite, tail_sprite

-- Start a random straight movement of a random distance vertically or horizontally, and loop it without delay.
function enemy:start_walking()

  local movement = sol.movement.create("straight")
  movement:set_speed(32)
  movement:set_angle(0)
  movement:start(self)
end

-- Replace body and tails sprite on position changed.
enemy:register_event("on_position_changed", function(enemy)

  
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  common_actions.learn(enemy, sprite)
  enemy:set_life(2)
  
  -- Create sprites.
  head_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  body_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/tail")
  tail_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/tail")
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_attack_consequence("thrown_item", 2)
  enemy:set_attack_consequence("hookshot", 2)
  enemy:set_attack_consequence("sword", 1)
  enemy:set_attack_consequence("arrow", 2)
  enemy:set_attack_consequence("boomerang", 2)
  enemy:set_attack_consequence("explosion", 2)
  enemy:set_hammer_reaction(2)
  enemy:set_fire_reaction(2)

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking()
end)
