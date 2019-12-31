-- Lua script of enemy hinox master.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local is_throw_upcoming = false
local is_holding_hero = false

-- Configuration variables
local waiting_duration = 500
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 32
local charging_speed = 128
local charging_maximum_distance = 100
local charging_probability = 0.5
local before_charging_delay  = 1000

local throwing_duration = 500
local bomb_duration = 600
local bomb_height = 16
local bomb_speed = 120
local projectile_offset_x = -24
local projectile_offset_y = -50

-- Start throwing behavior.
local function throw(right_hand, on_throwing)

  is_throw_upcoming = false
  sprite:set_animation("throwing")
  sprite:set_direction(right_hand and 2 or 0)

  sol.timer.start(enemy, throwing_duration, function()
    on_throwing()
    sprite:set_direction(right_hand and 0 or 2)
    sol.timer.start(enemy, bomb_duration, function()
      enemy:restart()
    end)
  end)
end

-- Start the enemy walking movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()

    -- At the end of the move, wait a few time then randomly charge or restart another move.
    sol.timer.start(enemy, waiting_duration, function()
      if math.random() > charging_probability then
        enemy:start_charging()
      else
        enemy:start_walking()
      end
    end)
  end)
end

-- Start the enemy charging movement.
function enemy:start_charging()

  sprite:set_animation("charge")
  sol.timer.start(enemy, before_charging_delay, function()
    enemy:start_straight_walking(enemy:get_angle(hero), charging_speed, charging_maximum_distance, function()
      enemy:restart()
    end)
    sprite:set_animation("charge")
    sprite:set_frame_delay(100)
  end)
end

-- Throw a bomb to the hero.
function enemy:throw_bomb()

  local x, y, layer = enemy:get_position()
  local hero_x, _ , _ = hero:get_position()
  local right_hand = hero_x > x
  throw(right_hand, function()
  
    local bomb = enemy:create_enemy({
      breed = "projectiles/bomb",
      x = right_hand and projectile_offset_x or 0 - projectile_offset_x,
      y = projectile_offset_y
    })
    bomb:go(bomb_duration, bomb_height, hero:get_angle(x + projectile_offset_x, y + projectile_offset_y) + math.pi, bomb_speed)
    bomb:explode_at_bounce()
  end)
end

-- Catch the hero.
function enemy:catch_hero()

  is_holding_hero = true
  enemy:stop_movement()
  sol.timer.stop_all(enemy)

  local x, y, layer = enemy:get_position()
  local center_x = camera:get_position() + camera:get_size() / 2.0
  local right_hand = center_x > x

  hero:freeze()
  hero:get_sprite():set_animation("scared")
  hero:set_position(x + projectile_offset_x, projectile_offset_y + y, layer + 1)

  throw(right_hand, function()
    -- TODO
    is_holding_hero = false
    hero:unfreeze()
  end)
end

-- Catch the hero on attacking him.
enemy:register_event("on_attacking_hero", function(enemy, hero, enemy_sprite)

  if not is_holding_hero then
    enemy:catch_hero()
  end
end)

-- Prepare to throw a bomb on hurt.
enemy:register_event("on_hurt", function(enemy)
  is_throw_upcoming = true
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(8)
  enemy:set_size(48, 32)
  enemy:set_origin(24, 29)
  enemy:set_hurt_style("boss")
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(4, {
    sword = 1,
    boomerang = 2,
    hookshot = 2,
    thrust = 2,
    jump_on = "ignored"
  })

  -- States.
  sprite:set_animation("waiting")
  enemy:set_damage(0)
  enemy:set_can_attack(true)
  if is_throw_upcoming then
    enemy:throw_bomb()
  else
    sol.timer.start(enemy, waiting_duration, function()
      enemy:start_walking()
    end)
  end
end)
