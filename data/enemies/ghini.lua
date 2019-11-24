-- Lua script of enemy ghini.
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
local circle = math.pi * 2.0

-- Configuration variables
local is_sleeping = enemy:get_property("is_sleeping")
local after_awake_delay = 1000
local take_off_duration = 1000
local flying_speed = 80
local flying_height = 16
local flying_acceleration = 8
local flying_deceleration = 16

-- Make the enemy flying movement.
function enemy:start_flying_movement()

  local enemy_x, _, _ = enemy:get_position()
  local camera_x, camera_y = camera:get_position()
  local camera_width, camera_height = camera:get_size()
  local target_x = math.random(camera_x, camera_x + camera_width)
  local target_y = math.random(camera_y + flying_height, camera_y + camera_height)

  -- Target the random point and start a new flying movement when reached.
  enemy:start_acceleration_walking(target_x, target_y, flying_speed, flying_acceleration, flying_deceleration, true, function()
    enemy:start_flying_movement()
  end)
  
  sprite:set_direction(target_x < enemy_x and 2 or 0)
end

-- Make the enemy wake up.
function enemy:wake_up()

  is_sleeping = false
  enemy:set_enabled(true)
  enemy:start_flying(take_off_duration, flying_height, function()
    sol.timer.start(enemy, after_awake_delay, function()
      enemy:start_flying_movement()
    end)
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(8)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(1, {
    hookshot = 2,
    thrust = 2,
    arrow = 4,
    fire = 4,
    boomerang = 8,
    bomb = 8,
    jump_on = "ignored",
  })

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  enemy:set_layer_independent_collisions(true)

  -- Wait for something external to wake up the enemy if it is sleeping, else start a fly that already took off.
  if is_sleeping then
    enemy:set_enabled(false)
  else
    sprite:set_xy(0, -flying_height)
    sol.timer.start(enemy, 10, function()
      enemy:start_flying_movement() -- Workaround: The camera position is 0, 0 here when entering a map, wait a frame before starting the move.
    end)
  end
end)
