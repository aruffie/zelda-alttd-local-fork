-- Lua script of enemy like_like.
-- This script is executed every time an enemy with this model is created.

-- Global variables.
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi / 2.0

-- Configuration variables
local walking_possible_angle = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 48
local walking_distance_grid = 16
local walking_max_move_by_step = 6
local walking_pause_duration = 1500

-- Start a random straight movement of a random distance on one of the 2 axis.
function enemy:start_like_like_walking()
  enemy:start_walking(walking_possible_angle, walking_speed, walking_distance_grid * math.random(walking_max_move_by_step), sprite)
end

-- Wait for a delay after each step and continue walking.
function enemy:on_walk_finished()

  sol.timer.start(enemy, walking_pause_duration, function()
    enemy:start_like_like_walking()
  end)
end

-- Make the enemy eat the hero, he still can do all actions but cannot move.
function enemy:eat_hero()

  enemy:stop_movement()
  hero:set_visible(false)
  hero:freeze()
  hero:set_position(enemy:get_position())

  -- TODO Once ate, do 8 action to get rid.

  -- TODO Eat whatever the shield is except the mirror one.
end

-- Passive behaviors needing constant checking.
function enemy:on_update()

  -- If the hero touches the enemy, eat him.
  if not enemy.is_eating then
    if enemy:overlaps(hero, "origin", sprite) then
      enemy.is_eating = false
      enemy:eat_hero()
    end
  end
end

-- Initialization.
function enemy:on_created()

  -- Game properties.
  enemy:set_life(2)
  enemy:set_can_attack(false)
  enemy.is_eating = false
  
  -- Behavior for each items.
  enemy:set_attack_consequence("sword", 1)
  enemy:set_attack_consequence("thrown_item", 2)
  enemy:set_attack_consequence("arrow", 2)
  enemy:set_attack_consequence("hookshot", 2)
  enemy:set_attack_consequence("fire", 2)
  enemy:set_attack_consequence("boomerang", 2)
  enemy:set_attack_consequence("explosion", 2)
  -- TODO enemy:set_attack_consequence("magic_rod", 2)

  -- Initial movement.
  enemy:start_like_like_walking()
end
