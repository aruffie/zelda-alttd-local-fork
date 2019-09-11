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
local is_jumping = false

-- Configuration variables.
local walking_possible_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 48
local walking_minimum_distance = 16
local walking_maximum_distance = 32
local waiting_duration = 800
local throwing_duration = 200
local jumping_triggering_distance = 50
local jumping_duration = 600
local jumping_height = 12
local jumping_speed = 100

local projectile_breed = "stone"
local projectile_offset = {{0, -8}, {0, -8}, {0, -8}, {0, -8}}

-- Start the enemy movement.
function enemy:start_walking(key)

  enemy:start_straight_walking(walking_possible_angles[key], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function() 
    sprite:set_animation("immobilized")
    sol.timer.start(enemy, waiting_duration, function()
      if not is_jumping then

        -- Throw an arrow if the hero is on the direction the enemy is looking at.
        if enemy:get_direction4_to(hero) == sprite:get_direction() then
          enemy:throw_projectile(projectile_breed, throwing_duration, projectile_offset[key][1], projectile_offset[key][2], function()
            enemy:start_walking(math.random(4))
          end)
        else
          enemy:start_walking(math.random(4))
        end
      end
    end)
  end)
end

-- Jump on sword triggering too close
game:register_event("on_command_pressed", function(game, command)

  if not enemy:exists() or not enemy:is_enabled() then
    return
  end

  if not is_jumping and command == "attack" and enemy:is_near(hero, jumping_triggering_distance) then
    is_jumping = true
    enemy:start_jumping(jumping_duration, jumping_height, enemy:get_angle(hero), jumping_speed, true, true)
    sprite:set_animation("jumping")
    sprite:set_direction(enemy:get_movement():get_direction4())
  end
end)

-- Restart enemy on jump finished.
enemy:register_event("on_jump_finished", function(enemy)
  enemy:restart()
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(1, {jump_on = "ignored"})

  -- States.
  is_jumping = false
  sprite:set_xy(0, 0)
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking(math.random(4))
end)