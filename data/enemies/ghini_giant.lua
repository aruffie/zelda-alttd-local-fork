-- Lua script of enemy giant ghini.
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
local is_sleeping = false
local target_x, target_y
local angle = math.random() * circle

-- Configuration variables
local take_off_duration = 1000
local flying_speed = 88
local flying_height = 16
local flying_angle_modifier = 0.03
local after_awake_delay = 1000

-- Make the enemy flying movement.
function enemy:start_flying_movement()

  local camera_x, camera_y = camera:get_position()
  local camera_width, camera_height = camera:get_size()
  target_x = math.random(camera_x, camera_x + camera_width)
  target_y = math.random(camera_y, camera_y + camera_height)

  -- Target a random point.
  local movement = enemy:start_straight_walking(angle, flying_speed)
  movement:set_ignore_obstacles(true)

  function movement:on_position_changed()

    -- Target a new point point when close enough to this one
    if enemy:get_distance(target_x, target_y) < 1.0 / flying_angle_modifier then
      enemy:start_flying_movement()
      return
    end

    -- Else slowly turn to the target. 
    local target_angle = enemy:get_angle(target_x, target_y)
    local relative_angle = (target_angle - angle) % circle
    local shortest_relative_angle = relative_angle < math.pi and relative_angle or relative_angle - circle
    angle = (angle + shortest_relative_angle * flying_angle_modifier) % circle
    movement:set_angle(angle)
    sprite:set_direction(movement:get_direction4())
  end
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

  is_sleeping = enemy:get_property("default_state") == "sleeping"
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
    charge = 2,
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

  -- Disable if sleeping, else start a fly that already took off.
  if is_sleeping then
    enemy:set_enabled(false)
  else
    sprite:set_xy(0, -flying_height)
    sol.timer.start(enemy, 10, function()
      enemy:start_flying_movement() -- Workaround: The camera position is 0, 0 here when entering a map, wait a frame before starting the move.
    end)
  end
end)
