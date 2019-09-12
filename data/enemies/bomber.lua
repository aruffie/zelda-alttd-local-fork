-- Lua script of enemy bomber.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local attacking_timer = nil

-- Configuration variables
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96
local flying_height = 16
local throwing_bomb_minimum_delay = 2000
local throwing_bomb_maximum_delay = 4000

local bomb_throw_duration = 600
local bomb_throw_speed = 40
local bomb_throw_angle = 3.0 * quarter - 0.4

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    enemy:start_walking()
  end)
end

-- Start throwing bomb.
function enemy:start_attacking()

  if attacking_timer then
    attacking_timer:stop()
  end

  attacking_timer = sol.timer.start(enemy, math.random(throwing_bomb_minimum_delay, throwing_bomb_maximum_delay), function()
    local bomb = enemy:create_enemy({breed = "projectiles/bomb"})

    -- Hide the begginning of the jump and make it visible only at the top.
    bomb:show(false)
    sol.timer.start(bomb, bomb_throw_duration / 3.0, function()
      bomb:set_position(enemy:get_position())
      bomb:show(true)
      bomb:get_movement():set_speed(bomb_throw_speed)
    end)

    -- Throw the bomb.
    bomb:go(bomb_throw_duration, flying_height, bomb_throw_angle, 0)
    bomb:explode_at_bounce()

    return math.random(throwing_bomb_minimum_delay, throwing_bomb_maximum_delay)
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(3)
  enemy:set_size(32, 24)
  enemy:set_origin(16, 21)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(3, {
    sword = 1,
    pegasus_boots = 2,
    explosion = "ignored",
    jump_on = "ignored"
  })

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:start_walking()
  enemy:start_attacking()
  sprite:set_xy(0, -flying_height) -- Directly fly without taking off movement.
end)
