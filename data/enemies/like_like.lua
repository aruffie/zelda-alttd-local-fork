-- Lua script of enemy like_like.
-- This script is executed every time an enemy with this model is created.

-- Global variables.
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local hero_sprite = hero:get_sprite()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5

local is_eating = false
local is_exhausted = false
local command_pressed_count = 0

-- Configuration variables.
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96
local walking_pause_duration = 1500
local is_exhausted_duration = 500

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    enemy:start_walking()
  end)
end

-- Free the hero.
function enemy:free_hero()

  is_eating = false
  is_exhausted = true

  -- Reset hero opacity.
  hero_sprite:set_opacity(255)
  hero:get_sprite("shadow"):set_opacity(255)
  hero:get_sprite("shadow_override"):set_opacity(255)

  -- Make enemy exhausted and walk, then restart after some time.
  enemy:set_invincible()
  enemy:set_damage(0)
  enemy:set_can_attack(false)

  sol.timer.start(enemy, is_exhausted_duration, function()
    enemy:restart()
  end)
end

-- Make the enemy eat the hero.
function enemy:eat_hero()

  is_eating = true
  command_pressed_count = 0
  enemy:stop_movement()
  enemy:set_invincible()

  -- Make the hero invisible, but still able to interact.
  hero_sprite:set_opacity(0)
  hero:get_sprite("shadow"):set_opacity(0)
  hero:get_sprite("shadow_override"):set_opacity(0)

  -- Eat the shield if it is the first variant and assigned to a slot.
  enemy:steal_item("shield", 1, true, true)
end

-- Store the number of command pressed while eaten, and free the hero once 8 action commands are pressed.
game:register_event("on_command_pressed", function(game, command)

  if not enemy:exists() or not enemy:is_enabled() then
    return
  end

  if is_eating and (command == "attack" or command == "item_1" or command == "item_2") then
    command_pressed_count = command_pressed_count + 1
    if command_pressed_count == 8 then
      enemy:free_hero()
      enemy:start_walking()
    end
  end
end)

-- Eat the hero if hurt.
-- TODO register_event() seems to not prevent the default behavior, check how to use it.
function enemy:on_attacking_hero(hero, enemy_sprite)

  if not is_eating and not is_exhausted and hero_sprite:get_opacity() ~= 0 then
    enemy:eat_hero()
  end
  return true
end

-- Free hero if dying.
enemy:register_event("on_dying", function(enemy)

  if is_eating then
    enemy:free_hero()
  end
end)

-- Passive behaviors needing constant checking.
enemy:register_event("on_update", function(enemy)

  -- Make sure the hero is stuck while eaten even if something move him.
  if is_eating then
    hero:set_position(enemy:get_position())
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
  enemy:set_hero_weapons_reactions(2, {
    sword = 1,
    jump_on = "ignored"})

  -- States.
  is_exhausted = false
  command_pressed_count = 0
  enemy:set_damage(1)
  enemy:set_can_attack(true)
  enemy:start_walking()
end)
