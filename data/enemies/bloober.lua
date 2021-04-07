----------------------------------
--
-- Bloober.
--
-- Swimming enemy for sideview maps.
-- Slighly fall to the depths, and swim to the top if the hero vertical position is greater than the enemy one.
--
----------------------------------

-- Global variables.
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local eighth = math.pi * 0.25

-- Configuration variables.
local gravity_speed = 8
local swimming_speed = 120
local swimming_distance = 40
local contracting_duration = 200
local waiting_minimum_duration = 500

-- Start swimming to the top.
local function start_swimming()

  sprite:set_animation("contracting")
  sol.timer.start(enemy, contracting_duration, function()
    local x = enemy:get_position()
    local hero_x = hero:get_position()
    local movement = enemy:start_straight_walking(hero_x > x and eighth or 3.0 * eighth, swimming_speed, swimming_distance, function()
      enemy:restart()
    end)
    sprite:set_animation("swimming")

    -- Stop the movement if the ground is not deep water anymore.
    function movement:on_position_changed()
      if map:get_ground_below(enemy:get_position()) ~= "deep_water" then
        movement:stop()
        enemy:restart()
      end
    end
  end)
end

-- Start gravity and waiting for an attack.
local function start_waiting()

  sprite:set_animation("waiting")
  enemy:start_straight_walking(3.0 * quarter, gravity_speed) -- Gravity.

  -- Attack if needed.
  sol.timer.start(enemy, waiting_minimum_duration, function()
    local _, y = enemy:get_position()
    local _, hero_y = hero:get_position()
    if y < hero_y then
      return 10
    end
    start_swimming()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions({
  	arrow = 1,
  	boomerang = 1,
  	explosion = 1,
  	sword = 1,
  	thrown_item = 1,
  	fire = 1,
  	jump_on = "ignored",
  	hammer = 1,
  	hookshot = 1,
  	magic_powder = 1,
  	shield = "protected",
  	thrust = 1
  })

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  start_waiting()
end)
