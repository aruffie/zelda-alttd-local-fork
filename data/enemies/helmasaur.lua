-- Lua script of enemy helmasaur.
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
local is_protected = true

-- Configuration variables
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 32
local weak_walking_speed = 48
local weak_walking_minimum_distance = 16
local weak_walking_maximum_distance = 96

local speed = walking_speed
local minimum_distance = walking_minimum_distance
local maximum_distance = walking_maximum_distance

-- Hurt if enemy and hero have same direction, else repulse.
local function on_sword_attack_received()

  -- Make sure to only trigger this event once by attack.
  enemy:set_invincible()

  if not is_protected or sprite:get_direction() == hero:get_direction() then
    enemy:hurt(1)
  else
    enemy:start_shock(hero, 100, 150, function()
      enemy:restart()
    end)
  end
end

-- Hurt if enemy and hero have same direction, else grab the mask and make enemy weak.
local function on_hookshot_attack_received()

  -- Make sure to only trigger this event once by attack.
  enemy:set_invincible()

  if not is_protected or sprite:get_direction() == hero:get_direction() then
    enemy:hurt(2)
  else
    enemy:set_weak()
  end
end

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], speed, math.random(minimum_distance, maximum_distance), function()
    enemy:start_walking()
  end)
end

-- Make the enemy faster and maskless.
function enemy:set_weak()

  is_protected = false

  speed = weak_walking_speed
  minimum_distance = weak_walking_minimum_distance
  maximum_distance = weak_walking_maximum_distance

  enemy:remove_sprite(sprite)
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/maskless")
  enemy:start_brief_effect("entities/effects/sparkle_small", "default", 0, 0)
  enemy:restart()
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
    hookshot = on_hookshot_attack_received,
    sword = on_sword_attack_received,
    jump_on = "ignored"
  })

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  enemy:start_walking()
end)
