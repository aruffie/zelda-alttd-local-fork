-- Lua script of enemy blue stalfos.
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
local is_unarmed = enemy:get_property("is_unarmed") == "true"
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96

local attack_triggering_distance = 64
local jumping_speed = 128
local jumping_height = 16
local jumping_duration = 600
local throwing_bone_delay = 200

-- Make this enemy throw bones or not.
function enemy:set_unarmed(unarmed)
  is_unarmed = unarmed or true
end

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    enemy:start_walking()
  end)
end

-- Event triggered when the enemy is close enough to the hero.
function enemy:start_attacking()

  -- Start jumping away from the hero.
  local hero_x, hero_y, _ = hero:get_position()
  local enemy_x, enemy_y, _ = enemy:get_position()
  local angle = math.atan2(hero_y - enemy_y, enemy_x - hero_x)
  enemy:start_jumping(jumping_duration, jumping_height, angle, jumping_speed)
  sprite:set_animation("jumping")
  enemy.is_exhausted = true
end

-- Make the enemy able to attack or not.
function enemy:set_exhausted(exhausted)
  enemy.is_exhausted = exhausted
end

-- Start attacking when the hero is near enough and an attack or item command is pressed, even if not assigned to an item.
game:register_event("on_command_pressed", function(game, command)

  if enemy:exists() and enemy:is_enabled() and not enemy.is_exhausted then
    if enemy:is_near(hero, attack_triggering_distance) and (command == "attack" or command == "item_1" or command == "item_2") then
      enemy:start_attacking()
    end
  end
end)

-- Start walking again when the attack finished.
enemy:register_event("on_jump_finished", function(enemy)

  -- Throw a bone club at the hero after a delay if the enemy is still alive.
  enemy:restart()
  if is_archer then
    sol.timer.start(enemy, throwing_bone_delay, function()
      
      if enemy:get_life() > 0 then
        local x, y, layer = enemy:get_position()
        local bone = map:create_enemy({
          breed = "projectiles/bone",
          x = x,
          y = y,
          layer = layer,
          direction = enemy:get_direction4_to(hero)
        })

        -- Call an enemy:on_enemy_created(bone) event.
        if enemy.on_enemy_created then
          enemy:on_enemy_created(bone)
        end
      end
    end)
  end
end)

-- Set exhausted on hurt.
enemy:register_event("on_hurt", function(enemy)
  enemy:set_exhausted(true)
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(3)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(2, {
    sword = 1,
    jump_on = "ignored",
    fire = "protected"})

  -- States.
  sprite:set_xy(0, 0)
  enemy.is_exhausted = false
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking()
end)
