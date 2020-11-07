----------------------------------
--
-- Peahat.
--
-- Flying enemy that regularly land off, move clockwise around the hero and land where he becomes vulnerable.
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5

-- Configuration variables
local frame_delay_step_duration = 500
local taking_off_frame_delay_steps = {640, 320, 160, 80, 40}
local landing_frame_delay_steps = {40, 40, 80, 160, 160, 320}
local take_off_duration = 1000
local flying_minimum_duration = 10000
local flying_maximum_duration = 11000
local landing_duration = 2000
local before_taking_off_delay = 2000
local before_moving_in_the_air_delay = 1000
local before_landing_delay = 500
local before_restarting_delay = 1000
local flying_height = 32
local flying_speed = 24
local turning_angle = 0.0075

-- Start a frame delay that will change later depending on the given table.
local function start_dynamic_frame_delay(steps_table, current_step, on_finished_callback)

  local step = current_step + 1
  sprite:set_frame_delay(steps_table[step])
  sol.timer.start(enemy, frame_delay_step_duration, function()
    if steps_table[step + 1] then
      start_dynamic_frame_delay(steps_table, step, on_finished_callback)
    elseif on_finished_callback then
      on_finished_callback()
    end
  end)
end

-- Start the enemy landing.
local function start_landing()

  enemy:stop_flying(landing_duration, function()
    sol.timer.start(enemy, before_restarting_delay, function()
      enemy:restart()
    end)
  end)
  start_dynamic_frame_delay(landing_frame_delay_steps, 0)
end

-- Start moving after some time.
local function start_moving()

  -- Start movements after some time.
  sol.timer.start(enemy, before_moving_in_the_air_delay, function()

    -- Start a straight movement.
    local angle = enemy:get_angle(hero) + quarter
    local movement = sol.movement.create("straight")
    movement:set_speed(flying_speed)
    movement:set_angle(angle)
    movement:set_smooth(true)
    movement:start(enemy)

    -- Slightly change the angle to make a circle movement.
    local turning_timer = sol.timer.start(enemy, 10, function()
      angle = angle - turning_angle
      movement:set_angle(angle)
      return true
    end)

    -- Start landing after some time.
    sol.timer.start(enemy, math.random(flying_minimum_duration, flying_maximum_duration), function()
      turning_timer:stop()
      movement:stop()
      sol.timer.start(enemy, before_landing_delay, function()
        start_landing()
      end)
    end)
  end)
end

-- Make the flying animation start and gradually decrease the frame delay.
local function start_taking_off()

    sprite:set_animation("walking")
    start_dynamic_frame_delay(taking_off_frame_delay_steps, 0, function()
      enemy:start_flying(take_off_duration, flying_height, function()
        start_moving()
      end)
      enemy:set_invincible()
    end)
end

-- Wait before taking off.
local function wait()

  sol.timer.start(enemy, before_taking_off_delay, function()
    start_taking_off()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(1, {jump_on = "ignored"})

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:set_obstacle_behavior("flying")
  enemy:set_layer_independent_collisions(true)
  sprite:set_animation("stopped")
  sprite:set_xy(0, 0)
  wait()
end)
