-- Lua script of enemy tektite.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5

-- Configuration variables
local waiting_minimum_duration = 500
local waiting_maximum_duration = 4000
local shaking_duration = 1000
local jumping_duration = 700
local jumping_height = 16
local jumping_speed = 128

-- Wait a few time and jump.
function enemy:wait()

  sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    sprite:set_animation("shaking")
    sol.timer.start(enemy, shaking_duration, function()

      sprite:set_animation("jumping")
      enemy:start_jumping(jumping_duration, jumping_height, enemy:get_angle(hero), jumping_speed, function()
        enemy:restart()
      end)
    end)
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(32, 24)
  enemy:set_origin(16, 21)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(2, {
    sword = 1
  })

  -- States.
  sprite:set_xy(0, 0)
  enemy:set_obstacle_behavior("normal")
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  enemy:wait()
end)
