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
local walking_speed = 48
local walking_distance_grid = 32
local walking_max_move_by_step = 1
local walking_maximum_extra_duration = 500
local throwing_animation_duration = 200

-- Start a random straight movement of a random distance vertically or horizontally, and loop it without delay.
function enemy:start_walking()

  enemy:start_random_walking(walking_possible_angle, walking_speed, walking_distance_grid * math.random(walking_max_move_by_step), function()
    sprite:set_animation("immobilized")
    sol.timer.start(enemy, math.random(walking_maximum_extra_duration), function()
      sprite:set_animation("inspect", function()

        -- If the hero is on the direction the enemy is looking at, throw an arrow.
        if enemy:get_direction4_to(hero) == sprite:get_direction() then
          enemy:throw_spear()
        else
          enemy:start_walking()
        end
      end)
    end)
  end)
end

-- Throw a spare
function enemy:throw_spear()

  sprite:set_animation("throwing")
  sol.timer.start(enemy, throwing_animation_duration, function()
    local x, y, layer = enemy:get_position()
    map:create_enemy({
      breed = "projectiles/spear",
      x = x,
      y = y,
      layer = layer,
      direction = enemy:get_direction4_to(hero)
    })
    enemy:start_walking()
  end)
end

-- Initialization.
function enemy:on_created()
  enemy:set_life(2)
end

-- Restart settings.
function enemy:on_restarted()

  -- Behavior for each items.
  enemy:set_attack_consequence("sword", 1)
  enemy:set_attack_consequence("thrown_item", 2)
  enemy:set_attack_consequence("hookshot", 2)
  enemy:set_attack_consequence("arrow", 2)
  enemy:set_attack_consequence("boomerang", 2)
  enemy:set_attack_consequence("explosion", 2)
  enemy:set_hammer_reaction(2)
  enemy:set_fire_reaction(2)

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking()
end
