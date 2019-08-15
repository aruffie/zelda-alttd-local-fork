-- Lua script of enemy gibdo.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
local common_actions = require("enemies/lib/common_actions")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())

-- Configuration variables
local frame_delay_step_duration = 500
local frame_delay_steps = {640, 320, 160, 80, 40}
local take_off_duration = 1000
local flying_height = 32

-- Start landing.
function enemy:start_moving()

  sprite:set_animation("walking")

  local function set_frame_delay_step(step)
    step = step + 1
    sprite:set_frame_delay(frame_delay_steps[step])
    sol.timer.start(enemy, frame_delay_step_duration, function()
      if frame_delay_steps[step + 1] then
        set_frame_delay_step(step)
      else
        enemy:start_flying(take_off_duration, true, flying_height)
      end
    end)
  end
  set_frame_delay_step(0)
end

-- Event called when the enemy took off.
function enemy:on_fly_took_off()

  -- Start a circle movement with the hero as center.
end

-- Initialization.
function enemy:on_created()

  common_actions.learn(enemy, sprite)
  enemy:set_life(300)
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
  enemy:start_moving()
end
