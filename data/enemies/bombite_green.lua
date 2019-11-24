-- Lua script of enemy bombite green.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local is_enemy_pushable = true
local is_running = false
local countdown_step = nil

-- Configuration variables
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_distance = 16
local running_speed = 80
local waiting_duration = 500
local number_duration = 1000

-- Make enemy follow the hero and start countdown before explode.
function on_regular_attack_received()

  if not is_running then
    is_running = true
    enemy:stop_movement()
    enemy:start_countdown()
  end
  if is_enemy_pushable then
    is_enemy_pushable = false
    enemy:start_pushed_back(hero, 100, 150) -- Don't use enemy:hurt(0) to not force the hurt animation and still repulse the enemy.
    sol.timer.start(map, 300, function() -- Only push once even if the sword still collide at following frames.
      is_enemy_pushable = true
      enemy:restart()
    end)
  end
end

-- Make the enemy start countdown.
function enemy:start_countdown()

  enemy:start_running()
  sol.timer.start(map, number_duration, function()   
    enemy:start_countdown_animation(3)
    sol.timer.start(map, number_duration, function()   
      enemy:start_countdown_animation(2)
      sol.timer.start(map, number_duration, function()   
        enemy:start_countdown_animation(1)
        sol.timer.start(map, number_duration, function()   
          local x, y, layer = enemy:get_position()
          map:create_explosion({
            x = x,
            y = y,
            layer = layer
          })
          enemy:remove()
        end)
      end)
    end)
  end)
end

-- Start the enemy countdown animation.
function enemy:start_countdown_animation(number)

  if number then
    countdown_step = number
    sprite:set_animation(number)
  else
    sprite:set_animation("smiling")
  end
end

-- Start the enemy walking movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, walking_distance, function()
    sol.timer.start(enemy, waiting_duration, function()
      if not is_running then
        enemy:start_walking()
      end
    end)
  end)
end

-- Start the enemy running movement.
function enemy:start_running(number)

  enemy:start_target_walking(hero, running_speed)
  enemy:start_countdown_animation(number)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions("ignored", {
    hookshot = "immobilized",
    boomerang = "immobilized",
    sword = on_regular_attack_received,
    explosion = on_regular_attack_received,
    thrust = on_regular_attack_received
  })

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  if not is_running then
    enemy:start_walking()
  else
    enemy:start_running(countdown_step)
  end
end)
