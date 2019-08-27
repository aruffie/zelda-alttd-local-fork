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
local walking_possible_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_distance_grid = 16
local walking_max_move_by_step = 6
local crushed_duration = 500

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_possible_angles[math.random(4)], walking_speed, walking_distance_grid * math.random(walking_max_move_by_step), function()
    enemy:start_walking()
  end)
end

-- Make enemy crushed when hero walking on him.
function enemy:on_custom_attack_received(attack)

  if attack == "jump_on" then

    -- Make enemy unable to interact.
    enemy:stop_movement()
    enemy:set_invincible()
    enemy:set_can_attack(false)
    enemy:set_damage(0)
    
    -- Set the "crushed" animation to its sprite if existing.
    if sprite:has_animation("crushed") then
      sprite:set_animation("crushed")
    end

    -- Hurt after a delay.
    sol.timer.start(enemy, crushed_duration, function()
      enemy:set_pushed_back_when_hurt(false)
      enemy:hurt(1)
    end)
  end
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
  enemy:set_jump_on_reaction("custom") -- Set crushed.

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking()
end
