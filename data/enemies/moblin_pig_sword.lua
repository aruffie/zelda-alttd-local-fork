-- Lua script of enemy moblin pig sword.
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
local walking_possible_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_distance_grid = 16
local walking_max_move_by_step = 6
local waiting_duration = 800

-- Start the enemy initial movement.
function enemy:start_walking()

  if not is_charging and enemy:is_near(hero, charge_triggering_distance) then
    enemy:start_charge_walking()
  else
    enemy:start_random_walking(math.random(4) - 1)
  end
end

-- Start the enemy random movement.
function enemy:start_random_walking(direction)

  enemy:start_straight_walking(walking_possible_angles[direction + 1], walking_speed, walking_distance_grid * math.random(walking_max_move_by_step), function()    
    local next_direction = math.random(4) - 1
    local waiting_animation = (direction + 1) % 4 == next_direction and "seek_left" or (direction - 1) % 4 == next_direction and "seek_right" or "immobilized"
    sprite:set_animation(waiting_animation)

    sol.timer.start(enemy, waiting_duration, function()
      if not is_charging then
        enemy:start_random_walking(next_direction)
      end
    end)
  end)
end

-- Start the enemy charge movement.
function enemy:start_charge_walking()

  is_charging = true
  enemy:stop_movement()
  enemy:start_target_walking(hero, charging_speed)
sprite:set_animation("seek_left")
end

test_x, test_y = enemy:get_position()
-- Passive behaviors needing constant checking.
function enemy:on_update()
enemy:set_position(test_x, test_y)
  if enemy:is_immobilized() then
    return
  end

  -- Start charging if the hero is near enough
  if not is_charging and enemy:is_near(hero, charge_triggering_distance) then -- TODO is seeing hero ?
    enemy:start_charge_walking()
  end
end

-- Initialization.
function enemy:on_created()
    enemy:set_life(2)
  enemy:hold_sword(sprite)
end

-- Restart settings.
function enemy:on_restarted()

  -- Behavior for each items.
  enemy:set_attack_consequence("sword", 1)
  enemy:set_attack_consequence("thrown_item", 2)
  enemy:set_attack_consequence("hookshot", 2)
  enemy:set_attack_consequence("arrow", 2)
  enemy:set_attack_consequence("boomerang", 2)
  enemy:set_attack_consequence("explosion", 2)
  enemy:set_hammer_reaction(2)
  enemy:set_fire_reaction(2)

  -- States.
  is_charging = false
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking()
end
