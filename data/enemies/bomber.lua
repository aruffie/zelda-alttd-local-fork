-- Lua script of enemy bomber.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local attacking_timer = nil

-- Configuration variables
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96
local flying_height = 16
local throwing_bomb_minimum_delay = 1500
local throwing_bomb_maximum_delay = 3000
local runaway_triggering_distance = 32
local runaway_speed = 200
local runaway_distance = 32

local bomb_throw_duration = 500
local bomb_throw_height = 20
local bomb_throw_speed = 80
local firing_duration = 500

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    enemy:start_walking()
  end)
end

-- Start throwing bomb.
function enemy:start_attacking()

  if attacking_timer then
    attacking_timer:stop()
  end

  -- Throw a bomb periodically.
  attacking_timer = sol.timer.start(enemy, math.random(throwing_bomb_minimum_delay, throwing_bomb_maximum_delay), function()

    local bomb = enemy:create_enemy({breed = "projectiles/bomb"})
    local angle = enemy:get_angle_from_sprite(sprite, hero)
    enemy:start_throwing(bomb, bomb_throw_duration, flying_height, bomb_throw_height, angle, bomb_throw_speed, function()
      bomb:explode()
    end)

    sprite:set_animation("firing")
    sol.timer.start(enemy, firing_duration, function()
      sprite:set_animation("walking")
    end)

    -- Call an enemy:on_enemy_created(bomb) event.
    if enemy.on_enemy_created then
      enemy:on_enemy_created(bomb)
    end

    return math.random(throwing_bomb_minimum_delay, throwing_bomb_maximum_delay)
  end)
end

-- Start the enemy runaway movement.
function enemy:runaway()

  enemy:start_straight_walking(enemy:get_angle_from_sprite(sprite, hero) + math.pi, runaway_speed, runaway_distance, function()
    enemy:start_walking()
  end)
end

-- Go away when attacking too close.
game:register_event("on_command_pressed", function(game, command)

  if enemy:exists() and enemy:is_enabled() and not enemy.is_exhausted then
    if enemy:is_near(hero, runaway_triggering_distance) and (command == "attack" or command == "item_1" or command == "item_2") then
      enemy:runaway()
    end
  end
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(3)
  enemy:set_size(32, 24)
  enemy:set_origin(16, 21)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(3, {
    sword = 1,
    thrust = 2,
    explosion = "ignored",
    jump_on = "ignored"
  })

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:start_walking()
  enemy:start_attacking()
  sprite:set_xy(0, -flying_height) -- Directly fly without taking off movement.
end)
