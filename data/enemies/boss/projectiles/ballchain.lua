-- Lua script of enemy rolling bones spike.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local ball_sprite
local chain_sprites = {}
local eighth = math.pi * 0.25
local quarter = math.pi * 0.5
local circle = math.pi * 2.0
local orbit_rotation_step, orbit_timer, orbit_angle
local chain_origin_offset_x, chain_origin_offset_y

-- Configuration variables
local orbit_initial_angle = 5 * eighth
local orbit_rotation_speed = 2 * circle
local orbit_attacking_rotation_speed = 3 * circle
local orbit_radius = 16
local before_attacking_minimum_duration = 1500
local throwing_speed = 200
local throwing_acceleration = 88
local throwing_deceleration = 88
local chain_maximum_length = 80

-- Update chain display depending on ball offset position.
local function update_chain()

  local x, y = ball_sprite:get_xy()
  for i = 1, 3 do
    chain_sprites[i]:set_xy((x - chain_origin_offset_x) / 4.0 * i + chain_origin_offset_x, (y - chain_origin_offset_y) / 4.0 * i + chain_origin_offset_y)
  end
end

-- Set the ball and chain sprites position during its orbit depending on angle.
local function set_orbit_position(angle)

  local x = math.cos(angle) * orbit_radius
  local y = -math.sin(angle) * orbit_radius

  ball_sprite:set_xy(x, y)
  update_chain()
end

-- Set an offset to the chain origin.
function enemy:set_chain_origin_offset(x, y)

  chain_origin_offset_x = x
  chain_origin_offset_y = y
end

-- Make the ball start orbitting around its origin, anti clockwise.
function enemy:start_orbitting()

  orbit_rotation_step = orbit_rotation_speed / 100.0

  set_orbit_position(orbit_angle)
  orbit_timer = sol.timer.start(enemy, 10, function()
    orbit_angle = (orbit_angle - orbit_rotation_step) % circle
    set_orbit_position(orbit_angle)
    return true
  end)
end

-- Make the ball start orbitting faster then go to the hero after some time.
function enemy:start_attacking(throwed_callback, pulled_callback, caught_callback)

  orbit_rotation_step = orbit_attacking_rotation_speed / 100.0
  sol.timer.start(enemy, before_attacking_minimum_duration, function()

    -- Start throwing the ball when the orbit angle is a quarter less than the angle to the hero.
    local x, y = enemy:get_position()
    local ball_x, ball_y = ball_sprite:get_xy()
    local hero_x, hero_y = hero:get_position()
    local hero_angle = sol.main.get_angle(x + ball_x, y + ball_y, hero_x, hero_y)
    local remaining_angle = (orbit_angle - hero_angle - quarter) % circle

    sol.timer.start(enemy, remaining_angle / orbit_attacking_rotation_speed * 1000, function()
      orbit_timer:stop()
      enemy:start_throwing(throwed_callback, pulled_callback, caught_callback)
    end)
  end)
end

-- Make the ball be throwed to the hero.
function enemy:start_throwing(throwed_callback, pulled_callback, caught_callback)

  local x, y, _ = enemy:get_position()
  local offset_x, offset_y = ball_sprite:get_xy()
  local hero_x, hero_y, _ = hero:get_position()
  local angle = sol.main.get_angle(x + offset_x, y + offset_y, hero_x, hero_y)

  local going_movement = sol.movement.create("straight")
  going_movement:set_speed(throwing_speed)
  going_movement:set_max_distance(chain_maximum_length)
  going_movement:set_angle(angle)
  going_movement:set_ignore_obstacles()
  going_movement:set_smooth(false)
  going_movement:start(ball_sprite)

  -- Start back movement when the ball reached the goal.
  function going_movement:on_finished()
    local target_x = math.cos(angle - quarter) * orbit_radius
    local target_y = -math.sin(angle - quarter) * orbit_radius

    local coming_movement = sol.movement.create("target")
    coming_movement:set_speed(throwing_speed)
    coming_movement:set_target(target_x, target_y)
    coming_movement:set_ignore_obstacles()
    coming_movement:set_smooth(false)
    coming_movement:start(ball_sprite)

    -- Start orbitting again once take back.
    function coming_movement:on_finished()
      orbit_angle = angle - quarter - orbit_rotation_step
      enemy:start_orbitting()
      if caught_callback then
        caught_callback()
      end
    end

    function coming_movement:on_position_changed()
      update_chain()
    end

    if pulled_callback then
      pulled_callback()
    end
  end

  function going_movement:on_position_changed()
    update_chain()
  end

  if throwed_callback then
    throwed_callback()
  end
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)

  for i = 3, 1, -1 do
    chain_sprites[i] = enemy:create_sprite("enemies/boss/ballchain_soldier/chain")
  end
  ball_sprite = enemy:create_sprite("enemies/boss/ballchain_soldier/ball")
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_invincible(true)
  enemy:set_damage(2)
  enemy:set_layer_independent_collisions(true)

  orbit_angle = orbit_initial_angle
  chain_origin_offset_x = 0
  chain_origin_offset_y = 0
  enemy:start_orbitting()
end)
