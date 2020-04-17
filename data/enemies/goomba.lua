----------------------------------
--
-- Goomba.
--
-- Moves randomly over horizontal and vertical axis, or horizontal axis only on sideview maps.
--
-- Methods : enemy:start_walking()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local is_sideview = string.find(map:get_id(), "sideview") and true or false -- Workaround: Sideview flag is set too late here, use the map id instead.

-- Configuration variables
local walking_angles = is_sideview and {0, 0, 2 * quarter, 2 * quarter} or {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96
local crushed_duration = 500

-- Start the enemy movement.
function enemy:start_walking()

  local distance = not is_sideview and math.random(walking_minimum_distance, walking_maximum_distance)
  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, distance, function()
    enemy:start_walking()
  end)
end

-- Don't hurt the hero if enemy is below on sideview maps.
enemy:register_event("on_attacking_hero", function(enemy, hero, enemy_sprite)

  local _, y, _ = enemy:get_position()
  local _, hero_y, _ = hero:get_position()
  if not is_sideview or hero_y >= y then
    hero:start_hurt(enemy, enemy:get_damage())
  end
end)

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
      sprite:set_animation("hurt_crushed")
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
