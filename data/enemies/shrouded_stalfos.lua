-- Lua script of enemy shrouded stalfos.
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
local walking_possible_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 48
local walking_distance_grid = 16
local walking_max_move_by_step = 2
local waiting_duration = 800
local throwing_duration = 200

local projectile_breed = "arrow"
local projectile_offset = {{0, -8}, {0, -8}, {0, -8}, {0, -8}}

-- Start the enemy movement.
function enemy:start_walking(key)

  enemy:start_straight_walking(walking_possible_angles[key], walking_speed, walking_distance_grid * math.random(walking_max_move_by_step), function() 
    sprite:set_animation("immobilized")
    sol.timer.start(enemy, waiting_duration, function()

      -- Throw an arrow if the hero is on the direction the enemy is looking at.
      if enemy:get_direction4_to(hero) == sprite:get_direction() then
        enemy:throw_projectile(projectile_breed, throwing_duration, true, projectile_offset[key][1], projectile_offset[key][2], function()
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

  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(2, {
    sword = 1, 
    jump_on = "ignored"})

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking(math.random(4))
end)