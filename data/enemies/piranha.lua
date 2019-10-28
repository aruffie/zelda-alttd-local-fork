-- Lua script of enemy piranha.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5

-- Configuration variables
local walking_angles = {0, 2.0 * quarter}
local walking_speed = 32
local waiting_minimum_duration = 2000
local waiting_maximum_duration = 4000
local jumping_duration = 600
local jumping_height = 16

-- Start the enemy movement.
function enemy:start_walking(direction)

  local movement = enemy:start_straight_walking(walking_angles[direction], walking_speed, nil, function()
    enemy:start_walking(direction % 2 + 1)
  end)

  function movement:on_position_changed()
    local x, y, layer = enemy:get_position()
    if not string.find(map:get_ground(x - 8, y, layer), "water") or not string.find(map:get_ground(x + 8, y, layer), "water") then
      movement:stop()
      enemy:start_walking(direction % 2 + 1)
    end
  end
end

-- Wait for some time then jump out of the water.
function enemy:dive(direction)

  enemy:set_hero_weapons_reactions("ignored")
  sprite:set_animation("walking")
  sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    enemy:jump()
  end)
end

-- Jump out of the water.
function enemy:jump(direction)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(2, {
    sword = 1
  })

  -- Jump dive when finished.
  sprite:set_animation("jumping")
  enemy:start_jumping(jumping_duration, jumping_height, nil, nil, function()
    enemy:start_brief_effect("enemies/zora", "disappearing")
    enemy:dive()
  end)

  -- Start diving animation at the middle of the jump.
  sol.timer.start(enemy, jumping_duration / 2.0, function()
    sprite:set_animation("diving")
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:set_obstacle_behavior("swimming")
  enemy:dive()
  enemy:start_walking(math.random(2))
end)
