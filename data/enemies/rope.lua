-- Lua script of enemy gibdo.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
require("scripts/multi_events")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local eighth = math.pi * 0.25

-- Configuration variables
local walking_possible_angle = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_distance_grid = 16
local walking_max_move_by_step = 6
local charging_speed = 88
local charging_max_distance = 100
local alignement_thickness = 16

local walking_pause_duration = 500
local is_exhausted_duration = 500

-- Get the closest angle between 0, pi/2, pi and 3pi/2.
local function get_closest_cardinal_angle(angle)
  return ((angle + eighth) - ((angle + eighth) % quarter)) % (math.pi * 2.0)
end

-- Start the enemy movement.
function enemy:start_walking()

  local movement = enemy:start_random_walking(walking_possible_angle, walking_speed, walking_distance_grid * math.random(walking_max_move_by_step), function()
    sol.timer.start(enemy, walking_pause_duration, function()
      if not enemy.is_charging then
        enemy:start_walking()
      end
    end)
  end)
end

-- Start charging.
function enemy:start_charging()

  enemy.is_charging = true

  enemy:stop_movement()
  local movement = sol.movement.create("straight")
  movement:set_speed(charging_speed)
  movement:set_max_distance(charging_max_distance)
  movement:set_angle(get_closest_cardinal_angle(enemy:get_angle(hero)))
  movement:set_smooth(false)
  movement:start(enemy)
  sprite:set_direction(movement:get_direction4())

  -- Stop charging on movement finished or obstacle reached.
  local function stop_charging()
    sol.timer.start(enemy, is_exhausted_duration, function()
      enemy:restart()
    end)
  end
  function movement:on_finished()
    stop_charging()
  end
  function movement:on_obstacle_reached()
    stop_charging()
  end
end

-- Passive behaviors needing constant checking.
function enemy:on_update()

  if not enemy:is_immobilized() then
    -- Start charging if the hero is aligned with the enemy.
    if not enemy.is_charging and enemy:is_aligned(hero, alignement_thickness) then
      enemy:start_charging()
    end
  end
end

-- Initialization.
enemy:register_event("on_created", function(enemy)
  enemy:set_life(1)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_attack_consequence("thrown_item", 1)
  enemy:set_attack_consequence("hookshot", 1)
  enemy:set_attack_consequence("sword", 1)
  enemy:set_attack_consequence("arrow", 1)
  enemy:set_attack_consequence("boomerang", 1)
  enemy:set_attack_consequence("explosion", 1)
  enemy:set_hammer_reaction(1)
  enemy:set_fire_reaction(1)

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  enemy.is_charging = false
  enemy:start_walking()
end)
