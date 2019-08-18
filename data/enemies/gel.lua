-- Lua script of enemy gel.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
local zol_behavior = require("enemies/lib/zol")
require("scripts/multi_events")

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local map = enemy:get_map()
local hero = map:get_hero()

-- Configuration variables
local slow_speed = 22
local stuck_duration = 2000

-- Passive behaviors needing constant checking.
function enemy:on_update()

  -- If the hero touches the center of the enemy, slow him down.
  if enemy.can_slow_hero_down and enemy:overlaps(hero, "origin") then
    enemy.can_slow_hero_down = false
    enemy:slow_hero_down()
  end
end

-- Make the hero slow down and make him unable to use weapons. 
function enemy:slow_hero_down()

  -- Stop potential current jump and slow the hero down
  enemy:stop_movement()
  sol.timer.stop_all(enemy)
  sprite:set_xy(0, 0)
  hero:set_walking_speed(slow_speed)
  
  -- Make the enemy follow the hero for a delay then make it jump away.
  local movement = sol.movement.create("target")
  movement:set_speed(slow_speed)
  movement:set_target(hero)
  movement:set_smooth(true)
  movement:start(enemy)
  sprite:set_animation("shaking")

  -- TODO Make the hero unable to use weapon while slowed down.

  -- Stop the slowdown after some time.
  sol.timer.start(enemy, stuck_duration, function()
    hero:set_walking_speed(88) -- TODO restore speed only if it's the last stuck gel.
    enemy:start_jump_attack(false)
  end)
end

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
  enemy:set_drawn_in_y_order(false)
  enemy.can_slow_hero_down = true
end)
