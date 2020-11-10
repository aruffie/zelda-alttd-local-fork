----------------------------------
--
-- Pols Voice.
--
-- Pounce forever to a random direction.
--
-- Methods : enemy:start_pouncing()
--           enemy:wait()
--
----------------------------------

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
function enemy:start_pouncing()

  sprite:set_animation("jumping")
  enemy:start_jumping(jumping_duration, jumping_height, math.random() * circle, jumping_speed, function()
    enemy:stop_movement()
    enemy:restart()
  end)
end

-- Wait before jumping.
function enemy:wait()

  sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    enemy:start_pouncing()
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

  enemy:set_hero_weapons_reactions({
  	arrow = 1,
  	boomerang = "immobilized",
  	explosion = 4,
  	sword = "protected",
  	thrown_item = 4,
  	fire = 1,
  	jump_on = "ignored",
  	hammer = "protected",
  	hookshot = "immobilized",
  	magic_powder = "immobilized",
  	shield = "protected",
  	thrust = "protected"
  })

  -- States.
  sprite:set_xy(0, 0)
  sprite:set_animation("walking")
  enemy:set_obstacle_behavior("normal")
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:wait()
end)
