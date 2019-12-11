-- Lua script of enemy tektite water.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local eighth = math.pi * 0.25

-- Configuration variables
local waiting_minimum_duration = 1000
local waiting_maximum_duration = 2000
local walking_angles = {eighth, 3.0 * eighth, 5.0 * eighth, 7.0 * eighth}
local walking_speed = 80
local walking_minimum_distance = 32
local walking_maximum_distance = 48
local walking_acceleration = 64
local walking_deceleration = 32

-- Start the enemy movement.
function enemy:start_walking()

  -- Target a random point depending on configuration.
  local x, y, layer = enemy:get_position()
  local angle, distance, target_x, target_y

  -- Raise warning if the enemy is misplaced on the map and can't move.
  if not enemy:is_fully_over_ground("water") then  
    print("Warning: Misplaced enemy " .. enemy:get_breed() .. " on " .. x .. "," .. y)
    return
  end

  -- Target a random target in the water.
  repeat 
    angle = walking_angles[math.random(4)]
    distance = math.random(walking_minimum_distance, walking_maximum_distance)
    target_x = x + math.cos(angle) * distance
    target_y = y + math.sin(angle) * distance
  until string.find(map:get_ground(target_x, target_y, layer), "water")

  -- Wait a few time then start accelerating.
  sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    local movement = enemy:start_impulsion(target_x, target_y, walking_speed, walking_acceleration, walking_deceleration)

    -- Stop movement if ground is not water anymore or obstacle reached.
    function movement:on_position_changed()
      if not enemy:is_fully_over_ground("water") then
        movement:stop()
        enemy:set_position(x, y, layer) -- Set back to the previous position.
        enemy:start_walking()
      end
      x, y, layer = enemy:get_position()
    end
    function movement:on_obstacle_reached()
      movement:stop()
      enemy:start_walking()
    end

    -- Start another movement on finished
    function movement:on_finished()
      enemy:start_walking()
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

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(1, {jump_on = "ignored"})

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  enemy:start_walking()
end)
