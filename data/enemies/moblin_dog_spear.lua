-- Lua script of enemy moblin dog spear.
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

local projectile_breed = "spear"
local projectile_offset = {{0, -11}, {8, 0}, {0, -11}, {-8, 0}}

-- Start the enemy movement.
function enemy:start_walking(key)

  enemy:start_straight_walking(walking_possible_angles[key], walking_speed, walking_distance_grid * math.random(walking_max_move_by_step), function()    
    local next_key = math.random(4)
    local waiting_animation = (key + 1) % 4 == next_key % 4 and "seek_left" or (key - 1) % 4 == next_key % 4 and "seek_right" or "immobilized"
    sprite:set_animation(waiting_animation)

    sol.timer.start(enemy, waiting_duration, function()

      -- Throw a spear if the hero is on the direction the enemy is looking at.
      if enemy:get_direction4_to(hero) == sprite:get_direction() then
        enemy:throw_projectile(projectile_breed, throwing_duration, projectile_offset[key][1], projectile_offset[key][2], function()
          enemy:start_walking(next_key)
        end)
      else
        enemy:start_walking(next_key)
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