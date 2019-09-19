-- Lua script of enemy leever.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
require("scripts/multi_events")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local eighth = math.pi * 0.25

-- Configuration variables
local walking_speed = 32
local walking_minimum_duration = 3000
local walking_maximum_duration = 5000
local waiting_minimum_duration = 2000
local waiting_maximum_duration = 3000

-- Return a random visible position.
local function get_random_visible_position()

  local x, y, _ =  enemy:get_position()
  local region_x, region_y, _ =  camera:get_position()
  local region_width, region_height = camera:get_size()

  while true do
    random_x = math.random(region_x, region_x + region_width)
    random_y = math.random(region_y, region_y + region_height)
    if not enemy:test_obstacles(random_x - x, random_y - y) then
      return random_x, random_y
    end
  end

  return nil
end

-- Start the enemy movement.
function enemy:start_walking()

  local movement = enemy:start_target_walking(hero, walking_speed)
  sol.timer.start(enemy, math.random(walking_minimum_duration, walking_maximum_duration), function()
    movement:stop()
    enemy:disappear()
  end)
end

-- Make the enemy appear at a random position.
function enemy:appear()

  enemy:set_position(get_random_visible_position())
  enemy:set_visible()
  sprite:set_animation("appearing", function()

    -- Behavior for each items.
    enemy:set_hero_weapons_reactions(2, {
      sword = 1,
      jump_on = "ignored"
    })
    enemy:set_can_attack(true)

    enemy:start_walking()
  end)
end

-- Make the enemy disappear.
function enemy:disappear()

  sprite:set_animation("disappearing", function()
    enemy:restart()
  end)
end

-- Wait a few time and appear.
function enemy:wait()

  sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    if not camera:overlaps(enemy:get_max_bounding_box()) then
      return waiting_duration
    end
    enemy:appear()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(16, 24)
  enemy:set_origin(8, 21)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- States.
  enemy:set_visible(false)
  enemy:set_can_attack(false)
  enemy:set_damage(2)
  enemy:set_invincible()
  enemy:wait()
end)

