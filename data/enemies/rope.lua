----------------------------------
--
-- Rope.
--
-- Moves randomly over horizontal and vertical axis, and charges the hero when aligned with him.
--
-- Methods : enemy:start_walking()
--           enemy:start_charging()
--
----------------------------------

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
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96
local charging_speed = 88
local charging_maximum_distance = 100
local alignement_thickness = 16

local walking_pause_duration = 500
local is_exhausted_duration = 500

-- Start the enemy movement.
function enemy:start_walking()

  local movement = enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
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
  movement:set_max_distance(charging_maximum_distance)
  movement:set_angle(enemy:get_direction4_to(hero) * quarter)
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
enemy:register_event("on_update", function(enemy)

  if enemy:is_immobilized() then
    return
  end

  -- Start charging if the hero is aligned with the enemy.
  if not enemy.is_charging and enemy:is_aligned(hero, alignement_thickness) then
    enemy:start_charging()
  end
end)

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
  enemy:set_damage(2)
  enemy.is_charging = false
  enemy:start_walking()
end)
