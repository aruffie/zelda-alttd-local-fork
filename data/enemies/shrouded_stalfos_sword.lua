-- Lua script of enemy shrouded stalfos sword.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
require("enemies/lib/weapons").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5

local is_charging = false

-- Configuration variables
local charge_triggering_distance = 80
local charging_speed = 56
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96
local waiting_duration = 800

-- Start the enemy initial movement.
function enemy:start_walking()

  if not is_charging and enemy:is_near(hero, charge_triggering_distance) then
    enemy:start_charge_walking()
  else
    enemy:start_random_walking(math.random(4))
  end
end

-- Start the enemy random movement.
function enemy:start_random_walking(key)

  enemy:start_straight_walking(walking_angles[key], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()    
    sprite:set_animation("immobilized")

    sol.timer.start(enemy, waiting_duration, function()
      if not is_charging then
        enemy:start_random_walking(math.random(4))
      end
    end)
  end)
end

-- Start the enemy charge movement.
function enemy:start_charge_walking()

  is_charging = true
  enemy:stop_movement()
  enemy:start_target_walking(hero, charging_speed)
  sprite:set_animation("chase")
end

-- Passive behaviors needing constant checking.
enemy:register_event("on_update", function(enemy)

  if enemy:is_immobilized() then
    return
  end

  -- Start charging if the hero is near enough
  if not is_charging and enemy:is_near(hero, charge_triggering_distance) then -- TODO is seeing hero ?
    enemy:start_charge_walking()
  end
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:hold_weapon("enemies/darknut/sword")
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(2, {
    sword = 1, 
    jump_on = "ignored"})

  -- States.
  is_charging = false
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking()
end)