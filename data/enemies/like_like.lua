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
local walking_speed = 32
local walking_distance_grid = 16
local walking_max_move_by_step = 6
local walking_pause_duration = 1500

local is_exhausted_duration = 1000
local is_hurt_duration = 500

-- Start a random straight movement of a random distance on one of the 2 axis.
function enemy:start_like_like_walking()
  enemy:start_walking(walking_possible_angle, walking_speed, walking_distance_grid * math.random(walking_max_move_by_step), sprite)
end

-- Start another random move on walk finished.
function enemy:on_walk_finished()
  enemy:start_like_like_walking()
end

-- Free the hero after he was eaten.
function enemy:free_hero()
    
  hero:set_walking_speed(88)
  hero:get_sprite():set_opacity(255)
  hero:get_sprite("shadow"):set_opacity(255)
  enemy.is_eating = false
  enemy.is_exhausted = true

  -- Make the enemy unable to directly eat again, nor the hero to hit him.
  sol.timer.start(enemy, is_exhausted_duration, function()
    enemy:set_default_attack_consequences()
    enemy.is_exhausted = false
  end)

  enemy:start_like_like_walking()

  -- TODO Eat whatever the shield is except the mirror one.
end

-- Store the number of command pressed while eaten and free the hero if necessary.
game:register_event("on_command_pressed", function(carriable, command)

  if enemy.is_eating and (command == "attack" or command == "item_1" or command == "item_2") then
    enemy.command_pressed_count = enemy.command_pressed_count + 1

    -- Once 8 action command are pressed, get the hero rid of the enemy.
    if enemy.command_pressed_count == 8 then
      enemy:free_hero()
    end
  end
end)

-- Make the enemy eat the hero
function enemy:eat_hero()

  -- Only make the hero sprite invisible so he still can do all actions but not move.
  enemy.is_eating = true
  enemy.command_pressed_count = 0
  enemy:stop_movement()
  enemy:set_invincible()
  hero:get_sprite():set_opacity(0)
  hero:get_sprite("shadow"):set_opacity(0)
  hero:set_position(enemy:get_position())
  hero:set_walking_speed(0)
end

-- Behavior on hurt.
function enemy:on_hurt(attack)
  enemy:set_can_attack(false)
  sol.timer.start(sol.main, is_hurt_duration, function() -- TODO Check why timer on enemy doesn't work
    enemy:start_like_like_walking()
  end)
end

-- Passive behaviors needing constant checking.
function enemy:on_update()

  -- If the hero touches the enemy, eat him.
  if not enemy.is_eating and not enemy.is_exhausted then
    if hero:overlaps(enemy, "origin") then
      enemy.is_eating = false
      enemy:eat_hero()
    end
  end
end

-- Initialization.
function enemy:on_created()

  -- Game properties.
  enemy:set_life(2)
  enemy:set_damage(0)
  enemy:set_can_attack(false)
  enemy.is_eating = false
  enemy.is_exhausted = false
  enemy.command_pressed_count = 0
  
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
