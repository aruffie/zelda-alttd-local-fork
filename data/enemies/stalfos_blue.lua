-- Lua script of enemy blue stalfos.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
local common_actions = require("enemies/lib/common_actions")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())

-- Configuration variables
local attack_triggering_distance = 32
local walking_speed = 32
local jumping_speed = 128
local jumping_height = 32
local jumping_duration = 800
local elevating_duration = 120
local stompdown_duration = 50

-- Start moving to the hero, and attack when he is close enough.
function enemy:start_walking()

  local movement = enemy:start_target_walking(hero, walking_speed)
  function movement:on_position_changed()
    if enemy:is_near(hero, attack_triggering_distance) then
      movement:stop()
      enemy:start_attacking()
    end
  end
end

-- Make the enemy move by targetting the hero.
function enemy:start_jumping_movement()

  -- Start the on-floor jumping movement.
  local target_x, target_y, _ = hero:get_position()
  local movement = sol.movement.create("target")
  movement:set_speed(jumping_speed)
  movement:set_target(target_x, target_y)
  movement:set_smooth(false)
  movement:start(enemy)
  sprite:set_animation("jumping")
end

-- Event triggered when the enemy is close enough to the hero.
function enemy:start_attacking()

  -- Start jumping on the current hero position.
  enemy:start_jumping_movement()
  enemy:start_flying(elevating_duration, jumping_height, true, true)

  -- Wait for a delay and start the stomp down.
  sol.timer.start(enemy, jumping_duration, function()
    enemy:stop_flying(stompdown_duration)
  end)
end

-- Start the attack animation when the jump reached the top.
function enemy:on_flying_took_off()
  sprite:set_animation("attack_landing")
end

-- Start walking again when the attack finished.
function enemy:on_flying_landed()

  -- Start a visual effect at the landing impact location.
  enemy:start_brief_effect("entities/effects/impact_projectile", "default", -12, 0)
  enemy:start_brief_effect("entities/effects/impact_projectile", "default", 12, 0)

  enemy:restart()
end

-- Initialization.
function enemy:on_created()

  common_actions.learn(enemy, sprite)
  enemy:set_life(3)
  enemy:add_shadow()
end

-- Restart settings.
function enemy:on_restarted()

  -- Behavior for each items.
  enemy:set_attack_consequence("sword", 1)
  enemy:set_attack_consequence("thrown_item", 2)
  enemy:set_attack_consequence("arrow", 2)
  enemy:set_attack_consequence("hookshot", 2)
  enemy:set_attack_consequence("fire", 2)
  enemy:set_attack_consequence("boomerang", 2)
  enemy:set_attack_consequence("explosion", 2)
  enemy:set_hammer_reaction(2)
  enemy:set_fire_reaction("protected")

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking()
end
