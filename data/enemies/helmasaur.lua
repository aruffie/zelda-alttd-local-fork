-- Lua script of enemy helmasaur.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
require("enemies/lib/weapons").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5

-- Configuration variables
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 32
local weak_walking_speed = 48
local weak_walking_minimum_distance = 16
local weak_walking_maximum_distance = 96

local speed = walking_speed
local minimum_distance = walking_minimum_distance
local maximum_distance = walking_maximum_distance

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], speed, math.random(minimum_distance, maximum_distance), function()
    enemy:start_walking()
  end)
end

-- Set the enemy weak.
function enemy:set_weak()

  speed = weak_walking_speed
  minimum_distance = weak_walking_minimum_distance
  maximum_distance = weak_walking_maximum_distance
  -- TODO Remove mask
  enemy:start_walking()
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:hold_weapon("enemies/" .. enemy:get_breed() .. "/mask")
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(2, {
    sword = 1,
    jump_on = "ignored"
  })

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking()
end)
