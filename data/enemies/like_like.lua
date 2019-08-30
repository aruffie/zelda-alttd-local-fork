-- Lua script of enemy like_like.
-- This script is executed every time an enemy with this model is created.

-- Global variables.
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
local walking_pause_duration = 1500
local is_exhausted_duration = 500

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_possible_angles[math.random(4)], walking_speed, walking_distance_grid * math.random(walking_max_move_by_step), function()
    enemy:start_walking()
  end)
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

  enemy:start_walking()
end

-- Make the enemy eat the hero
-- TODO Make a custom state instead of handling hero in enemy script.
function enemy:eat_hero()

  enemy.is_eating = true
  enemy.command_pressed_count = 0
  enemy:stop_movement()
  enemy:set_invincible()

  -- Make the hero sprite invisible so he still can do all actions but can't move.
  hero:get_sprite():set_opacity(0)
  hero:get_sprite("shadow"):set_opacity(0)
  hero:set_position(enemy:get_position())
  hero:set_walking_speed(0)

  -- Eat the shield if it is the first variant and assigned to a slot.
  enemy:steal_item("shield", 1, true)
end

-- Store the number of command pressed while eaten and free the hero if necessary.
game:register_event("on_command_pressed", function(game, command)

  if enemy:exists() and enemy:is_enabled() then
    if enemy.is_eating and (command == "attack" or command == "item_1" or command == "item_2") then
      enemy.command_pressed_count = enemy.command_pressed_count + 1

      -- Once 8 action commands are pressed, get the hero rid of the enemy.
      if enemy.command_pressed_count == 8 then
        enemy:free_hero()
      end
    end
  end
end)

-- Passive behaviors needing constant checking.
enemy:register_event("on_update", function(enemy)

  if enemy:is_immobilized() then
    return
  end

  -- If the enemy is eating, make the hero stuck at the same position even if external things may hurt or interfere.
  if enemy.is_eating then
    hero:set_position(enemy:get_position())
  end

  -- If the hero touches the enemy while he is walking normally, eat him.
  if not enemy.is_eating and not enemy.is_exhausted and hero:overlaps(enemy, "origin") then
    enemy.is_eating = false
    enemy:eat_hero()
  end
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions({
    sword = 1,
    jump_on = "ignored",
    default = 2})

  -- States.
  enemy:set_damage(0)
  enemy:set_can_attack(false)
  enemy.is_eating = false
  enemy.is_exhausted = false
  enemy.command_pressed_count = 0
  enemy:start_walking()
end)
