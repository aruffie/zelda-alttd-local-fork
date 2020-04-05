-- Lua script of enemy dodongo_snake.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local head_sprite, body_sprite
local last_positions = {}
local frame_count = 0
local quarter = math.pi * 0.5

-- Configuration variables
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 24
local walking_minimum_distance = 16
local walking_maximum_distance = 32
local body_frame_lag = 14
local bomb_eating_duration = 1000

local highest_frame_lag = body_frame_lag + 1 -- Avoid too much values in the last_positions table

-- Return the given table minus sprite direction and its opposite.
function enemy:get_possible_moving_angles(angles)

  local possible_angles = {}
  local sprite_direction = head_sprite:get_direction()
  for _, angle in ipairs(angles) do
    if sprite_direction * quarter ~= angle and (sprite_direction + 2) % 4 * quarter ~= angle then
      possible_angles[#possible_angles + 1] = angle
    end
  end
  return possible_angles
end

-- Start the enemy movement.
function enemy:start_walking()

  local possible_angles = enemy:get_possible_moving_angles(walking_angles)
  enemy:start_straight_walking(possible_angles[math.random(#possible_angles)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    enemy:start_walking()
  end)
end

-- Passive behaviors needing constant checking.
enemy:register_event("on_update", function(enemy)

  -- Eat the bomb when the bomb sprite hit the center of the head.
  for entity in map:get_entities_in_region(enemy) do
    if entity:get_type() == "bomb" and entity:overlaps(enemy, "center") then
      enemy:stop_movement()
      entity:remove()
      head_sprite:set_animation("bomb_eating", function()
        head_sprite:set_animation("immobilized")
        body_sprite:set_animation("bomb_eating")
        sol.timer.start(enemy, bomb_eating_duration, function()
          body_sprite:set_animation("exploding", function()
            local angle = head_sprite:get_direction() * quarter
            local effect_x = math.cos(angle) * 16
            local effect_y = -math.sin(angle) * 16
            enemy:start_brief_effect("entities/effects/brake_smoke", "default", effect_x, effect_y)
            enemy:hurt(1)
          end)
        end)
      end)
    end
  end
end)


-- Update body sprite on position changed whatever the movement is.
enemy:register_event("on_position_changed", function(enemy)

  if not body_sprite then
    return
  end

  -- Save current position
  local x, y, _ = enemy:get_position()
  last_positions[frame_count] = {x = x, y = y}

  -- Replace body sprite on a previous position.
  local previous_position = last_positions[(frame_count - body_frame_lag) % highest_frame_lag] or last_positions[0]
  body_sprite:set_xy(previous_position.x - x, previous_position.y - y)

  frame_count = (frame_count + 1) % highest_frame_lag
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(3)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)

  body_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/body")
  head_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- States.
  enemy:set_invincible()
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:start_walking()
end)
