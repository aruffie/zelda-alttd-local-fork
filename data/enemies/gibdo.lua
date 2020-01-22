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
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96
local stalfos_shaking_duration = 500

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    enemy:start_walking()
  end)
end

-- On hit by fire, the gibdo become a red Stalfos.
enemy:register_event("on_custom_attack_received", function(enemy, attack)

  if attack == "fire" then
    local x, y, layer = enemy:get_position()
    stalfos = enemy:create_enemy({
      name = (enemy:get_name() or enemy:get_breed()) .. "_stalfos",
      breed = "stalfos_red"
    })

    -- Make the Stalfos immobile, then shake for some time, and then restart.
    stalfos:set_invincible()
    stalfos:stop_movement()
    stalfos:set_exhausted(true)
    sol.timer.stop_all(stalfos)
    stalfos:get_sprite():set_animation("shaking")
    sol.timer.start(stalfos, stalfos_shaking_duration, function()
      stalfos:restart()
    end)

    enemy:remove()
  end
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(6)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(1, {
    boomerang = 2,
    hammer = 2,
    explosion = 3,
    jump_on = "ignored",
    thrown_item = "ignored",
    hookshot = "immobilized",
    fire = "custom"})

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:start_walking()
end)
