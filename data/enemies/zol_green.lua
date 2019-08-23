-- Lua script of enemy zol_green.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local zol_behavior = require("enemies/lib/zol")
require("scripts/multi_events")

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local shadow
local jump_count = 0

-- Configuration variables
local between_jump_duration = 500
local max_jump_combo = 8
local max_distance = 60
local is_awake = false

-- Make the enemy appear.
function enemy:appear()

  is_awake = true
  sprite:set_animation("appearing")
  shadow:set_visible()
  function sprite:on_animation_finished(animation)
    if animation == "appearing" then
      sprite:set_animation("shaking")
      enemy:set_can_attack(true)
      sol.timer.start(enemy, 1000, function()
        jump_count = 1
        enemy:start_jump_attack(true)
      end)
    end
  end
end

-- Make the enemy disappear.
function enemy:disappear()

  is_awake = false
  enemy:set_can_attack(false)
  shadow:set_visible(false)
  sprite:set_animation("disappearing")
  function sprite:on_animation_finished(animation)
    if animation == "disappearing" then
      sprite:set_animation("invisible")
      enemy:start_waiting_for_hero()
    end
  end
end

-- Wait for the hero to be close enough and appear if yes.
function enemy:start_waiting_for_hero()

  sol.timer.start(enemy, 100, function()
    if enemy:get_distance(hero) < max_distance then
      enemy:appear()
      return false
    end
    return true
  end)
end

-- Start a new jump if the hero is near enough and jump combo not finished, or make the enemy disappear.
function enemy:on_attack_finished()

  if enemy:get_distance(hero) > max_distance or jump_count >= math.random(max_jump_combo) then
    enemy:disappear()
  else
    sol.timer.start(enemy, between_jump_duration, function()
      jump_count = jump_count + 1
      enemy:start_jump_attack(true)
    end)
  end
end

-- Initialization.
enemy:register_event("on_created", function(enemy)
  zol_behavior.apply(enemy, {sprite = sprite})
  shadow = enemy:get_shadow()
end)

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
  enemy:set_damage(2)
  if not is_awake then
    enemy:start_waiting_for_hero()
    sprite:set_animation("invisible")
    shadow:set_visible(false)
  else 
    enemy:on_attack_finished()
  end
end)
