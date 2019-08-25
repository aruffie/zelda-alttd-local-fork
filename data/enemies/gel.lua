-- Lua script of enemy gel.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
local zol_behavior = require("enemies/lib/zol")
require("scripts/multi_events")

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

-- Configuration variables
local slow_speed = 22
local stuck_duration = 2000
local stuck_maximum_extra_duration = 500

-- Let go the hero.
function enemy:free_hero()

  enemy:stop_leashed_by(hero)

  -- Restore the hero speed and weapons only if there are no more leashed gel.
  local is_hero_free = true
  for enemy in map:get_entities_by_type("enemy") do
    if enemy.is_leashed_by and enemy:is_leashed_by(hero) then
      is_hero_free = false
    end
  end
  if is_hero_free then
    -- TODO
    hero:set_walking_speed(88)
  end
end

-- Make the hero slow down and unable to use weapons. 
function enemy:slow_hero_down()

  -- Stop potential current jump and slow the hero down.
  enemy:stop_movement()
  sol.timer.stop_all(enemy)
  sprite:set_xy(0, 0)
  hero:set_walking_speed(slow_speed)
  
  -- Make the enemy follow the hero.
  enemy:start_leashed_by(hero, 6)
  sprite:set_animation("shaking")

  -- TODO Make the hero unable to use weapon while slowed down.
  --game:set_ability("sword", 0)
  --game:set_item_assigned(1, nil)
  --game:set_item_assigned(2, nil)

  -- Jump away after some time.
  sol.timer.start(enemy, stuck_duration + math.random(stuck_maximum_extra_duration), function()
    enemy:free_hero()
    enemy:start_jump_attack(false)
  end)
end

-- Passive behaviors needing constant checking.
function enemy:on_update()

  if not enemy:is_immobilized() then
    -- If the hero touches the center of the enemy, slow him down.
    if enemy.can_slow_hero_down and enemy:get_life() > 0 and enemy:overlaps(hero, "origin") then
      enemy.can_slow_hero_down = false
      enemy:slow_hero_down()
    end
  end
end

-- Free the hero on dying
function enemy:on_dying()
  enemy:free_hero()
end

-- Start walking again when the attack finished.
enemy:register_event("on_jump_finished", function(enemy)
  enemy:restart()
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)
  zol_behavior.apply(enemy, {sprite = sprite, walking_speed = 2})
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
  enemy:set_can_attack(false)
  enemy:set_damage(0)
  enemy.can_slow_hero_down = true
  enemy:start_walking()
end)
