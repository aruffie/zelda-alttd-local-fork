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

-- Configuration variables
local orbit_initial_angle = 5 * eighth
local orbit_rotation_speed = 2 * circle
local orbit_attacking_rotation_speed = 3 * circle
local orbit_radius = 16
local before_attacking_minimum_duration = 1500
local throwing_speed = 88
local throwing_acceleration = 64
local throwing_deceleration = 32
local chain_maximum_length = 100

-- Start a straight move to the given offset target and apply a constant acceleration and deceleration (px/s²).
local function start_sprite_impulsion(sprite, x, y, speed, acceleration, deceleration)

  -- Workaround : Don't use solarus movements to be able to start several movements at the same time.
  local movement = {}
  local timers = {}
  local angle = enemy:get_angle(x, y)
  local start = {enemy:get_position()}
  local target = {x, y}
  local accelerations = {acceleration, acceleration}
  local trigonometric_functions = {math.cos, math.sin}

  -- Call given event on the movement table.
  local function call_event(event)
    if event then
      event(movement)
    end
  end

  -- Schedule 1 pixel moves on each axis depending on the given acceleration.
  local function move_on_axis(axis)

    local axis_current_speed = math.abs(trigonometric_functions[axis](angle) * 2.0 * acceleration)
    local axis_maximum_speed = math.abs(trigonometric_functions[axis](angle) * speed)
    local axis_move = {[axis % 2 + 1] = 0, [axis] = math.max(-1, math.min(1, target[axis] - start[axis]))}

    -- Avoid too low speed (less than 1px/s).
    if axis_current_speed < 1 then
      accelerations[axis] = 0
      return
    end

    return sol.timer.start(enemy, 1000.0 / axis_current_speed, function()

      -- Move sprite.
      sprite:set_xy(axis_move[1], axis_move[2])
      call_event(movement.on_position_changed)

      -- Replace axis acceleration by negative deceleration if beyond axis target.
      if accelerations[axis] > 0 and math.min(start[axis], axis_move[axis]) <= target[axis] and target[axis] <= math.max(start[axis], axis_move[axis]) then
        accelerations[axis] = -deceleration
        call_event(movement.on_changed)

        -- Call decelerating callback if both axis timers are decelerating.
        if accelerations[axis % 2 + 1] <= 0 then
          call_event(movement.on_decelerating)
        end
      end

      -- Update speed between 0 and maximum speed (px/s) depending on acceleration.
      axis_current_speed = math.min(math.sqrt(math.max(0, math.pow(axis_current_speed, 2.0) + 2.0 * accelerations[axis])), axis_maximum_speed)     

      -- Schedule the next pixel move and avoid too low timers (less than 1px/s).
      if axis_current_speed >= 1 then
        return 1000.0 / axis_current_speed
      end

      -- Call on_finished() event when the last axis timers finished normally.
      timers[axis] = nil
      if not timers[axis % 2 + 1] then
        call_event(movement.on_finished)
      end
    end)
  end
  timers = {move_on_axis(1), move_on_axis(2)}

  -- TODO Reproduce generic build-in movement methods on the returned movement table.
  function movement:stop()
    for i = 1, 2 do
      if timers[i] then
        timers[i]:stop()
      end
    end
  end
  function movement:set_ignore_obstacles(ignore)
    ignore_obstacles = ignore or true
  end
  function movement:get_direction4()
    return math.floor((angle / circle * 8 + 1) % 8 / 2)
  end

  return movement
end

-- Set the ball and chain sprites position during its orbit depending on angle.
local function set_orbit_position(angle)

  local x = math.cos(angle) * orbit_radius
  local y = -math.sin(angle) * orbit_radius

  ball_sprite:set_xy(x, y)
  for i = 1, 3 do
    chain_sprites[i]:set_xy(x / 4.0 * i, y / 4.0 * i)
  end
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
function enemy:start_attacking(throwed_callback, takeback_callback)

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
      enemy:start_throwing(throwed_callback, takeback_callback)
    end)
  end)
end

-- Make the ball be throwed to the hero.
function enemy:start_throwing(throwed_callback, takeback_callback)

  local angle = sol.main.get_angle(0, 0, ball_sprite:get_xy())
  local target_x = math.cos(angle) * chain_maximum_length
  local target_y = -math.sin(angle) * chain_maximum_length
  local impulsion = start_sprite_impulsion(ball_sprite, target_x, target_y, throwing_speed, throwing_acceleration, throwing_deceleration)
  if throwed_callback then
    throwed_callback()
  end

  -- Start back movement when the ball reached the goal.
  function impulsion:on_finished()

    target_x = math.cos(orbit_initial_angle) * orbit_radius
    target_y = -math.sin(orbit_initial_angle) * orbit_radius
    local back_impulsion = start_sprite_impulsion(ball_sprite, target_x, target_y, throwing_speed, throwing_acceleration, throwing_deceleration)
    function back_impulsion:on_decelerating()
      enemy:restart()
      if takeback_callback then
        takeback_callback()
      end
    end
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
  enemy:set_drawn_in_y_order(false)

  orbit_angle = orbit_initial_angle
  enemy:start_orbitting()
end)
