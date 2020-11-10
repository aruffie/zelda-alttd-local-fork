----------------------------------
--
-- Tektite Water.
--
-- Wait a few time then go to a diagonal direction with acceleration and deceleration, and restarts.
-- Can only move over water grounds.
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local circle = math.pi * 2.0
local quarter = math.pi * 0.5
local eighth = math.pi * 0.25

-- Configuration variables
local waiting_minimum_duration = 1000
local waiting_maximum_duration = 2000
local walking_angles = {eighth, 3.0 * eighth, 5.0 * eighth, 7.0 * eighth}
local walking_speed = 80
local walking_minimum_distance = 32
local walking_maximum_distance = 48
local walking_acceleration = 256
local walking_deceleration = 32

-- Return true if the enemy can move at least one pixel to the given angle without reaching an obstacle or bad ground.
local function is_obstacle_free(angle)

  local x_offset = (angle < quarter or angle > 3.0 * quarter) and 1 or (angle > quarter and angle < 3.0 * quarter) and -1 or 0
  local y_offset = (angle > 0 and angle < math.pi) and -1 or (angle > math.pi and angle < circle) and 1 or 0

  return enemy:is_over_grounds({"shallow_water", "deep_water"}, x_offset, y_offset)
end

-- Start the enemy movement.
local function start_walking()

  -- Target a random point depending on configuration.
  local x, y, layer = enemy:get_position()
  local angle = walking_angles[math.random(4)]
  local distance = math.random(walking_minimum_distance, walking_maximum_distance)

  -- Try another walk if the chosen angle would reach an obstacle
  if not is_obstacle_free(angle) then
    start_walking()
    return
  end

  -- Wait a few time then start accelerating.
  sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    local movement = enemy:start_impulsion(angle, walking_speed, walking_acceleration, walking_deceleration, distance)

    -- Stop movement if ground is not water anymore or obstacle reached.
    function movement:on_position_changed()
      if not enemy:is_over_grounds({"shallow_water", "deep_water"}) then
        movement:stop()
        enemy:set_position(x, y, layer) -- Set back to the previous position.
        enemy:restart()
      end
      x, y, layer = enemy:get_position()
    end
    function movement:on_obstacle_reached()
      enemy:restart()
    end

    -- Start another movement on finished
    function movement:on_finished()
      enemy:restart()
    end
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:set_obstacle_behavior("swimming")
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

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
  start_walking()
end)
