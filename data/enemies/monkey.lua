-- Lua script of enemy "monkey".
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local is_knocked_off = false

-- Configuration variables
local waiting_duration = 2000
local second_thow_delay = 200
local falling_duration = 600
local falling_height = 16
local falling_angle = 3 * quarter - 0.4
local falling_speed = 100
local running_speed = 100

local projectile_initial_speed = 150

-- Start throwing animation and create a coconut enemy when finished.
function enemy:start_throwing_coconut(direction, angle, on_throwed_callback)

  sprite:set_direction(direction)
  sprite:set_animation("throwing", function()
    local projectile_breed = math.random(10) ~= 1 and "coconut" or "bomb" -- Throw a bomb once in a while.
    local projectile = enemy:create_enemy({breed = "projectiles/" .. projectile_breed})
    projectile:go(nil, nil, angle, projectile_initial_speed)

    sprite:set_animation("walking")
    if on_throwed_callback then
      on_throwed_callback()
    end

    -- Call an enemy:on_enemy_created(projectile) event.
    if enemy.on_enemy_created then
      enemy:on_enemy_created(projectile)
    end
  end)
end

-- Throw two coconuts.
function enemy:attack()
 
  enemy:start_throwing_coconut(0, 3.0 * quarter + 0.5, function()
    attacking_timer = sol.timer.start(enemy, second_thow_delay, function()
      if not is_knocked_off then
        enemy:start_throwing_coconut(2, 3.0 * quarter - 0.5, function()
          enemy:wait()
        end)
      end
    end)
  end)
end

-- Wait a delay and start attacking.
function enemy:wait()

  sprite:set_animation("walking")
  sol.timer.start(enemy, waiting_duration, function()
    if not is_knocked_off then
      enemy:attack()
    end
  end)
end

-- Make the enemy knock off and run away.
function enemy:start_knocking_off()

  is_knocked_off = true
  enemy:start_jumping(falling_duration, falling_height, falling_angle, falling_speed)
  sprite:set_animation("falling")
end

-- Start runing away after falling down.
enemy:register_event("on_jump_finished", function(enemy)

  sol.timer.start(enemy, waiting_duration, function()
    local direction = math.random(4)
    local movement = enemy:start_straight_walking(direction * quarter, running_speed)
    sprite:set_animation("escape")

    -- Remove the enemy once out of screen.
    movement:set_ignore_obstacles(true)
    function movement:on_position_changed()
      if not camera:overlaps(enemy:get_max_bounding_box()) then
        enemy:remove()
      end
    end
  end)
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_invincible(true)

  -- States.
  enemy:set_damage(0)
  enemy:set_can_attack(false)
  enemy:wait()
end)