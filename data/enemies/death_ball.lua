-- Lua script of enemy death_ball.
-- This script is executed every time an enemy with this model is created.

-- Global variables.
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())

-- Configuration variables
local attraction_on_hero_step_delay = 50

-- Aspire or expluse the hero by one pixel and loop.
function enemy:update_attraction()

  if enemy.is_aspiring or enemy.is_explusing then
    enemy:attract_hero(enemy.is_aspiring and 1 or -1)
  end
  sol.timer.start(enemy, attraction_on_hero_step_delay, function()
    enemy:update_attraction()
  end)
end

-- Start an enemy state.
function enemy:start_state(state)

  enemy.is_aspiring = false
  enemy.is_explusing = false

  if state == "aspiring" then
    enemy.is_aspiring = true
  elseif state == "expulsing" then
    enemy.is_explusing = true
  end
end

-- Initialization.
function enemy:on_created()

  enemy:set_life(1)
  enemy.is_aspiring = false
  enemy.is_explusing = false
end

function enemy:on_restarted()
  
  enemy:set_can_attack(false)
  enemy:set_pushed_back_when_hurt(false)
  enemy:start_state(enemy:get_property("default_state"))
  enemy:update_attraction()
end
