-- Lua script of enemy "monkey".
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5

-- Configuration variables
local waiting_duration = 2000
local second_thow_delay = 200

local coconut_initial_speed = 150

-- Start throwing animation and create a coconut enemy when finished.
function enemy:start_throwing_coconut(direction, angle, on_throwed_callback)

  sprite:set_direction(direction)
  sprite:set_animation("throwing", function()
    local coconut = enemy:create_enemy({breed = "projectiles/coconut"}) -- TODO Throw a bomb once in a while.
    coconut:go(angle, coconut_initial_speed)
    sprite:set_animation("walking")
    if on_throwed_callback then
      on_throwed_callback()
    end
  end)
end

-- Throw two coconuts.
function enemy:attack()
 
  enemy:start_throwing_coconut(0, 3.0 * quarter + 0.5, function()
    sol.timer.start(enemy, second_thow_delay, function()
      enemy:start_throwing_coconut(2, 3.0 * quarter - 0.5, function()
        enemy:wait()
      end)
    end)
  end)
end

-- Wait a delay and start attacking.
function enemy:wait()

  sprite:set_animation("walking")
  sol.timer.start(enemy, waiting_duration, function()
    enemy:attack()
  end)
end

-- Make the enemy knock off and run away.
function enemy:start_knocking_off()

  sprite:set_animation("falling")
  -- TODO
end

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_invincible(true)

  -- States.
  enemy:set_damage(1)
  enemy:set_can_attack(false)
  enemy:wait()
end)