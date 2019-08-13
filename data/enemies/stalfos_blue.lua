-- Lua script of enemy blue stalfos.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/stalfos").apply(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:get_sprite()

-- Configuration variables
local attack_triggering_distance = 32
local walking_speed = 32
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
  enemy:start_jumping_movement(target_x, target_y)
  enemy:start_flying(elevating_duration, true, jumping_height)

  -- Wait for a delay and start the stomp down.
  sol.timer.start(enemy, jumping_duration, function()
    enemy:stop_flying(stompdown_duration)
  end)
end

-- Start walking again when the attack finished.
function enemy:on_fly_landed()

  -- Start a visual effect at the landing impact location.
  local x, y, layer = enemy:get_position()
  local impact_entity = map:create_custom_entity({
      direction = 0,
      x = x,
      y = y,
      layer = layer,
      width = 80,
      height = 32,
      sprite = "entities/effects/sparkle_small" -- TODO
  })
  local impact_sprite = impact_entity:get_sprite()
  function impact_sprite:on_animation_finished()
    impact_entity:remove()
  end

  enemy:restart()
end
