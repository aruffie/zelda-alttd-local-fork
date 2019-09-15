-- Lua script of enemy spiked beetle.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
require("scripts/multi_events")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local eighth = math.pi * 0.25
local is_upside_down = false

-- Configuration variables
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 24
local walking_minimum_distance = 16
local walking_maximum_distance = 96
local charging_speed = 100
local charging_max_distance = 100
local alignement_thickness = 16

local jumping_speed = 40
local jumping_height = 15
local jumping_duration = 500

local walking_pause_duration = 500
local is_exhausted_duration = 500
local upside_down_duration = 4500
local shaking_duration = 500
local before_charging_delay = 100

-- Start the enemy movement.
function enemy:start_walking()

  local movement = enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    sol.timer.start(enemy, walking_pause_duration, function()
      if not is_charging and not is_upside_down then
        enemy:start_walking()
      end
    end)
  end)
end

-- Start charging.
function enemy:start_charging()

  is_charging = true

  sol.timer.start(enemy, before_charging_delay, function()
    if is_charging and not is_upside_down then

      -- Charging movement.
      enemy:stop_movement()
      local movement = sol.movement.create("straight")
      movement:set_speed(charging_speed)
      movement:set_max_distance(charging_max_distance)
      movement:set_angle(enemy:get_direction4_to(hero) * quarter)
      movement:set_smooth(false)
      movement:start(enemy)
      sprite:set_direction(movement:get_direction4())

      -- Stop charging on movement finished or obstacle reached.
      local function stop_charging()
        sol.timer.start(enemy, is_exhausted_duration, function()
          if is_charging and not is_upside_down then
            enemy:restart()
          end
        end)
      end
      function movement:on_finished()
        stop_charging()
      end
      function movement:on_obstacle_reached()
        stop_charging()
      end
    end
  end)
end

-- Flip the enemy on collision with the shield and make it vulnerable.
enemy:register_event("on_shield_collision", function(enemy, shield)

  if not is_upside_down then
    is_upside_down = true
    is_charging = false
    enemy:stop_movement()
    enemy:set_hero_weapons_reactions(2, {sword = 1})
    enemy:start_brief_effect("entities/effects/impact_projectile", "default")

    -- Make the enemy jump while flipping.
    local angle = sprite:get_direction() * quarter + math.pi
    enemy:start_jumping(jumping_duration, jumping_height, angle, jumping_speed)
    sprite:set_animation("renverse")
  end
end)

-- Wait for a delay and restart the enemy when flipped.
enemy:register_event("on_jump_finished", function(enemy)

  sol.timer.start(enemy, upside_down_duration, function()
    if is_upside_down then
      sprite:set_animation("shaking")
      sol.timer.start(enemy, shaking_duration, function()
        if is_upside_down then
          enemy:restart()
        end
      end)
    end
  end)
end)

-- Passive behaviors needing constant checking.
enemy:register_event("on_update", function(enemy)

  if enemy:is_immobilized() then
    return
  end

  -- Start charging if the hero is aligned with the enemy.
  if not is_charging and not is_upside_down and enemy:is_aligned(hero, alignement_thickness) then
    enemy:start_charging()
  end
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(24, 24)
  enemy:set_origin(12, 21)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions("protected", {jump_on = "ignored"})

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  is_charging = false
  is_upside_down = false
  enemy:start_walking()
end)
