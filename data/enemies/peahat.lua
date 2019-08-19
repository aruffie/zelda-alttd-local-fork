-- Lua script of enemy gibdo.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
local common_actions = require("enemies/lib/common_actions")

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
local flying_duration = 10000
local flying_maximum_extra_duration = 1000
local landing_duration = 2000
local before_taking_off_delay = 2000
local before_moving_in_the_air_delay = 1000
local before_landing_delay = 500
local before_restarting_delay = 1000
local flying_height = 32
local flying_speed = 24

-- Start a frame delay that will change later depending on the given table.
function enemy:start_dynamic_frame_delay(steps_table, current_step, finished_callback)

  local step = current_step + 1
  sprite:set_frame_delay(steps_table[step])
  sol.timer.start(enemy, frame_delay_step_duration, function()
    if steps_table[step + 1] then
      enemy:start_dynamic_frame_delay(steps_table, step, finished_callback)
    elseif finished_callback then
      finished_callback()
    end
  end)
end

-- Start landing after some time.
function enemy:start_moving()

  sol.timer.start(enemy, before_taking_off_delay, function()

    -- Make the flying animation start and gradually decrease the frame delay.
    sprite:set_animation("walking")
    enemy:start_dynamic_frame_delay(taking_off_frame_delay_steps, 0, function()
      enemy:start_flying(take_off_duration, flying_height, true, true)
    end)
  end)
end

-- Event called when the enemy took off.
function enemy:on_fly_took_off()

  -- Start in the air movements after some time.
  sol.timer.start(enemy, before_moving_in_the_air_delay, function()

    -- Start a straight movement and always slighty change the angle.
    local movement = sol.movement.create("straight")
    movement:set_speed(flying_speed)
    movement:set_angle(enemy:get_angle(hero) + quarter)
    movement:set_smooth(true)
    movement:start(enemy)
    function movement:on_position_changed()
      movement:set_angle(movement:get_angle() - 0.02)
    end

    -- Start landing after some time.
    sol.timer.start(enemy, flying_duration + math.random(flying_maximum_extra_duration), function()
      movement:stop()
      sol.timer.start(enemy, before_landing_delay, function()
        enemy:stop_flying(landing_duration)
        enemy:start_dynamic_frame_delay(landing_frame_delay_steps, 0)
      end)
    end)
  end)
end

-- Restart the enemy on landed.
function enemy:on_fly_landed()
  sol.timer.start(enemy, before_restarting_delay, function()
    enemy:restart()
  end)
end

-- Initialization.
function enemy:on_created()

  common_actions.learn(enemy, sprite)
  enemy:set_life(1)
  enemy:add_shadow()
end

-- Restart settings.
function enemy:on_restarted()

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
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  sprite:set_animation("stopped")
  enemy:start_moving()
end
