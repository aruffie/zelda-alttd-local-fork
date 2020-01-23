-- Lua script of enemy pols voice.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local circle = math.pi * 2.0

-- Configuration variables
local jumping_duration = 800
local jumping_height = 16
local jumping_speed = 48
local waiting_minimum_duration = 500
local waiting_maximum_duration = 700

-- Start the enemy movement.
function enemy:start_moving()

  sprite:set_animation("jumping")
  enemy:start_jumping(jumping_duration, jumping_height, math.random() * circle, jumping_speed, function()
    enemy:stop_movement()
    enemy:restart()
  end)
end

-- Wait before jumping.
function enemy:wait()

  sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    enemy:start_moving()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(4)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions("protected", {
    arrow = 1,
    fire = 1,
    bomb = 4,
    thrown_item = 4,
    boomerang = "immobilized",
    hookshot = "immobilized",
    magic_powder = "immobilized",
    jump_on = "ignored"
  })

  -- States.
  sprite:set_animation("walking")
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:wait()
end)
