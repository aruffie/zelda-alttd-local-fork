-- Lua script of enemy blue stalfos.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

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

-- Event triggered when the enemy is close enough to the hero.
function enemy:start_attacking()

  -- Start jumping on the current hero position.
  local target_x, target_y, _ = hero:get_position()
  local movement = sol.movement.create("target")
  movement:set_speed(jumping_speed)
  movement:set_target(target_x, target_y)
  movement:set_smooth(false)
  movement:start(enemy)
  enemy:start_flying(elevating_duration, jumping_height)
  sprite:set_animation("jumping")

  -- Wait for a delay and start the stomp down.
  sol.timer.start(enemy, jumping_duration, function()
    enemy:stop_flying(stompdown_duration)
  end)
end

-- Start the attack animation when the jump reached the top.
enemy:register_event("on_flying_took_off", function(enemy)
  sprite:set_animation("attack_landing")
end)

-- Start walking again when the attack finished.
enemy:register_event("on_flying_landed", function(enemy)

  -- Start a visual effect at the landing impact location.
  enemy:start_brief_effect("entities/effects/impact_projectile", "default", -12, 0)
  enemy:start_brief_effect("entities/effects/impact_projectile", "default", 12, 0)
  enemy:restart()
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
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking()
end)
