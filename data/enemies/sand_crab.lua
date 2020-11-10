----------------------------------
--
-- Sand Crab.
--
-- Moves randomly over horizontal and vertical axis, with a different speed depending on the axis.
--
-- Methods : enemy:start_walking()
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

-- Configuration variables
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speeds = {80, 16, 80, 16}
local walking_minimum_distance = 16
local walking_maximum_distance = 96

-- Start the enemy movement.
local function start_walking()

  local direction = math.random(4)
  enemy:start_straight_walking(walking_angles[direction], walking_speeds[direction], math.random(walking_minimum_distance, walking_maximum_distance), function()
    start_walking()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(32, 32)
  enemy:set_origin(16, 29)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_hero_weapons_reactions({
  	arrow = 2,
  	boomerang = 2,
  	explosion = 2,
  	sword = 1,
  	thrown_item = 2,
  	fire = 2,
  	jump_on = "ignored",
  	hammer = 2,
  	hookshot = 2,
  	magic_powder = 2,
  	shield = "protected",
  	thrust = 2
  })

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  start_walking()
end)
