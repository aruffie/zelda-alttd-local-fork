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
local walking_possible_angle = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_distance_grid = 16
local walking_max_move_by_step = 6

local burn_duration = 1500

-- Start a random straight movement of a random distance vertically or horizontally, and loop it without delay.
function enemy:start_walking()

  math.randomseed(sol.main.get_elapsed_time())
  enemy:start_random_walking(walking_possible_angle, walking_speed, walking_distance_grid * math.random(walking_max_move_by_step), function()
    enemy:start_walking()
  end)
end

-- On hit by fire.
function enemy:on_custom_attack_received(attack)

  if attack == "fire" then

    -- Immobilize the enemy
    enemy:set_pushed_back_when_hurt(false)
    enemy:immobilize()
    sol.timer.start(sol.main, burn_duration, function()

      -- Then replace it by a red Stalfos.
      local x, y, layer = enemy:get_position()
      enemy:remove()
      map:create_enemy({
        breed = "stalfos_red",
        x = x,
        y = y,
        layer = layer,
        direction = enemy:get_direction4_to(hero)
      })
    end)
  end
end

-- Initialization.
function enemy:on_created()

  common_actions.learn(enemy, sprite)
  enemy:set_life(6)
end

-- Restart settings.
function enemy:on_restarted()

  -- Behavior for each items.
  enemy:set_attack_consequence("thrown_item", "ignored")
  enemy:set_attack_consequence("hookshot", "immobilized")
  enemy:set_fire_reaction("custom") -- Transform into red Stalfos
  enemy:set_attack_consequence("sword", 1)
  enemy:set_attack_consequence("arrow", 1)
  enemy:set_attack_consequence("boomerang", 2)
  enemy:set_attack_consequence("explosion", 3)
  enemy:set_hammer_reaction(2)

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:start_walking()
end
