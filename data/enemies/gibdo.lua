-- Lua script of enemy gibdo.
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
local walking_possible_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_distance_grid = 16
local walking_max_move_by_step = 6
local stalfos_shaking_duration = 500

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_possible_angles[math.random(4)], walking_speed, walking_distance_grid * math.random(walking_max_move_by_step), function()
    enemy:start_walking()
  end)
end

-- On hit by fire, the gibdo become a red Stalfos.
function enemy:on_custom_attack_received(attack)

  if attack == "fire" then
    local x, y, layer = enemy:get_position()
    stalfos = enemy:create_enemy({breed = "stalfos_red"})
    enemy:remove()

    -- Make the Stalfos immobile, then shake for some time, and then restart.
    stalfos:set_exhausted(true)
    stalfos:stop_movement()
    sol.timer.stop_all(stalfos)
    stalfos:get_sprite():set_animation("shaking")
    sol.timer.start(stalfos, stalfos_shaking_duration, function()
      stalfos:restart()
    end)
  end
end

-- Initialization.
function enemy:on_created()

  enemy:set_life(6)
end

-- Restart settings.
function enemy:on_restarted()

  -- Behavior for each items.
  enemy:set_attack_consequence("thrown_item", "ignored")
  enemy:set_attack_consequence("hookshot", "immobilized")
  enemy:set_attack_consequence("sword", 1)
  enemy:set_attack_consequence("arrow", 1)
  enemy:set_attack_consequence("boomerang", 2)
  enemy:set_attack_consequence("explosion", 3)
  enemy:set_hammer_reaction(2)
  enemy:set_fire_reaction("custom") -- Transform into red Stalfos

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:start_walking()
end
