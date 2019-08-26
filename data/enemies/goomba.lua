-- Lua script of enemy goomba.
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
local walking_possible_angle = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_distance_grid = 16
local walking_max_move_by_step = 6

-- Start a random straight movement of a random distance vertically or horizontally, and loop it without delay.
function enemy:start_walking()

  enemy:start_random_walking(walking_possible_angle, walking_speed, walking_distance_grid * math.random(walking_max_move_by_step), function()
    enemy:start_walking()
  end)
end

-- Initialization.
function enemy:on_created()
  enemy:set_life(1)
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
  enemy:set_jump_on_reaction(1)

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking()
end
