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
local attracting_pixel_by_second = 88

-- Start an enemy state.
function enemy:start_state(state)

  if state == "attracting" then
    enemy:start_attracting(hero, attracting_pixel_by_second)
  elseif state == "expulsing" then
    enemy:start_attracting(hero, attracting_pixel_by_second, true)
  else
    enemy:stop_attracting()
  end
end

-- Initialization.
function enemy:on_created()

  enemy:set_life(1)
end

function enemy:on_restarted()
  
  enemy:set_can_attack(false)
  enemy:set_pushed_back_when_hurt(false)

  -- Default state given by property.
  enemy:start_state(enemy:get_property("default_state"))
end
