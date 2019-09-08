-- Lua script of enemy goomba.
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
local walking_possible_angles = map:is_sideview() and {0, quarter, 2.0 * quarter, 3.0 * quarter} or {0, 0, 2 * quarter, 2 * quarter}
local walking_speed = 32
local walking_distance_grid = 16
local walking_max_move_by_step = 6
local crushed_duration = 500

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_possible_angles[math.random(4)], walking_speed, walking_distance_grid * math.random(walking_max_move_by_step), function()
    enemy:start_walking()
  end)
end

-- Don't hurt the hero if enemy is below on sideview maps.
function enemy:on_attacking_hero(hero, enemy_sprite)

  local _, y, _ = enemy:get_position()
  local _, hero_y, _ = hero:get_position()
  if map:is_sideview() and hero_y < y then
    return
  end
  hero:start_hurt(enemy, enemy:get_damage())
end

-- Make enemy crushed when hero walking on him.
enemy:register_event("on_custom_attack_received", function(enemy, attack)

  if attack == "jump_on" then

    -- Make enemy unable to interact.
    enemy:stop_movement()
    enemy:set_invincible()
    enemy:set_can_attack(false)
    enemy:set_damage(0)
    
    -- Set the "crushed" animation to its sprite if existing.
    if sprite:has_animation("crushed") then
      sprite:set_animation("crushed")
    end

    -- Hurt after a delay.
    sol.timer.start(enemy, crushed_duration, function()
      enemy:set_pushed_back_when_hurt(false)
      enemy:hurt(1)
    end)
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
  enemy:set_hero_weapons_reactions(1, {jump_on = "custom"})

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking()
end)
