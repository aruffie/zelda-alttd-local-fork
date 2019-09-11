-- Lua script of enemy octorok.
-- This script is executed every time an enemy with this model is created.

local enemy = ...
require("scripts/multi_events")
require("enemies/lib/weapons").learn(enemy)
  
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5

-- Configuration variables.
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 48
local walking_minimum_distance = 16
local walking_maximum_distance = 32
local waiting_duration = 800
local throwing_duration = 200

local projectile_breed = "stone"
local projectile_offset = {{0, -8}, {0, -8}, {0, -8}, {0, -8}}

-- Start the enemy movement.
function enemy:start_walking(key)

  enemy:start_straight_walking(walking_angles[key], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function() 
    sprite:set_animation("immobilized")
    sol.timer.start(enemy, waiting_duration, function()

      -- Throw an arrow if the hero is on the direction the enemy is looking at.
      if enemy:get_direction4_to(hero) == sprite:get_direction() then
        enemy:throw_projectile(projectile_breed, throwing_duration, projectile_offset[key][1], projectile_offset[key][2], function()
          enemy:start_walking(math.random(4))
        end)
      else
        enemy:start_walking(math.random(4))
      end
    end)
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
  enemy:set_hero_weapons_reactions(1, {jump_on = "ignored"})

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking(math.random(4))
end)