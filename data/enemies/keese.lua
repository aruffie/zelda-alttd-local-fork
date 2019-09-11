-- Lua script of enemy keese.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
require("scripts/multi_events")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local eighth = math.pi * 0.25
local waiting_timer = nil

-- Configuration variables
local triggering_distance = 48
local walking_speed = 32
local walking_minimum_duration = 3000
local walking_maximum_duration = 5000

-- Start the enemy movement.
function enemy:start_walking()

  local movement = enemy:start_straight_walking(enemy:get_angle(hero) + quarter, walking_speed)
  movement:set_ignore_obstacles()
  function movement:on_position_changed()
    movement:set_angle(movement:get_angle() - 0.02)
  end
  sol.timer.start(enemy, math.random(walking_minimum_duration, walking_maximum_duration), function()
    movement:stop()
    enemy:wait()
  end)
end

-- Wait for the hero to be close enough.
function enemy:wait()

  sprite:set_animation("stopped")
  if waiting_timer then
    waiting_timer:stop()
  end
  waiting_timer = sol.timer.start(enemy, 50, function()
    if not enemy:is_near(hero, triggering_distance) then
      return 50
    end
    enemy:start_walking()
    waiting_timer = nil
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(24, 16)
  enemy:set_origin(12, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(1, {jump_on = "ignored"})

  -- States.
  enemy:set_can_attack(false)
  enemy:set_damage(2)
  enemy:wait()
end)

