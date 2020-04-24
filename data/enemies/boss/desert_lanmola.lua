-- Lua script of enemy desert_lanmola.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local head_sprite, tail_sprite
local body_sprites = {}
local last_positions, frame_count
local eighth = math.pi * 0.25
local sixteenth = math.pi * 0.125
local circle = math.pi * 2.0

-- Configuration variables
local tunnel_duration = 1000
local waiting_minimum_duration = 2000
local waiting_maximum_duration = 4000
local jumping_speed = 48
local jumping_height = 32
local jumping_minimum_duration = 2500
local jumping_maximum_duration = 3500
local body_frame_lags = {15, 30, 45, 60, 75}
local tail_frame_lag = 90
local angle_amplitude_from_center = sixteenth

local highest_frame_lag = tail_frame_lag + 1 -- Avoid too much values in the last_positions table

-- Return a random visible position.
local function get_random_visible_position()

  local x, y, _ =  camera:get_position()
  local width, height = camera:get_size()
  return math.random(x, x + width), math.random(y, y + height)
end

-- Update body and tail sprites depending on current and previous positions.
local function update_body_sprites()

  -- Save current head sprite position if it is still visible.
  local x, y, _ = enemy:get_position()
  local x_offset, y_offset = head_sprite:get_xy()
  if head_sprite:get_opacity() ~= 0 then
    last_positions[frame_count] = {x = x + x_offset, y = y + y_offset}
  else
    last_positions[frame_count] = nil
  end

  -- Replace part sprites on a previous position.
  local function replace_part_sprite(sprite, frame_lag)
    local key = (frame_count - frame_lag) % highest_frame_lag

    -- Make sprite invisible if no stored position, and visible if position available but sprite still invisible.
    if not last_positions[key] then
      if sprite:get_opacity() ~= 0 then
        sprite:set_opacity(0)
      end
      return
    end
    if sprite:get_opacity() == 0 then
      sprite:set_opacity(255)
    end

    sprite:set_xy(last_positions[key].x - x, last_positions[key].y - y)
  end
  for i = 1, 5 do
    replace_part_sprite(body_sprites[i], body_frame_lags[i])
  end
  replace_part_sprite(tail_sprite, tail_frame_lag)

  frame_count = (frame_count + 1) % highest_frame_lag
end

-- Make all sprites invisible and at the 0, 0 offset position.
local function reset_sprites()

  local function reset(sprite)
    sprite:set_xy(0, 0)
    sprite:set_opacity(0)
  end
  
  reset(head_sprite)
  for i = 1, 5 do
    reset(body_sprites[i])
  end
  reset(tail_sprite)
end

-- Update all sprites z-order depending on the enemy moving angle.
local function update_sprites_order(angle)

  local head_on_front = angle > math.pi and angle < circle
  local order_method = head_on_front and enemy.bring_sprite_to_back or enemy.bring_sprite_to_front

  order_method(enemy, head_sprite)
  for i = 1, 5 do
    order_method(enemy, body_sprites[i])
  end
  order_method(enemy, tail_sprite)
end

-- Set the correct direction8 to all sprites depending on the given angle.
local function update_sprites_direction(angle)

  local direction8 = math.floor((angle + sixteenth) % circle / eighth)

  head_sprite:set_direction(direction8)
  for i = 1, 5 do
    body_sprites[i]:set_direction(direction8)
  end
  tail_sprite:set_direction(direction8)
end

-- Create a tunnel and appear at a random position.
function enemy:start_tunneling()

  -- Postpone to the next frame if the random position would be over an obstacle.
  local x, y, _ = enemy:get_position()
  local random_x, random_y = get_random_visible_position()
  if enemy:test_obstacles(random_x - x, random_y - y) then
    sol.timer.start(enemy, 10, function()
      enemy:start_tunneling()
    end)
    return
  end

  enemy:set_position(random_x, random_y)
  enemy:start_brief_effect("enemies/" .. enemy:get_breed() .. "/dust", "tunnel", 0, 0, tunnel_duration)
  sol.timer.start(enemy, tunnel_duration, function()
    enemy:appear()  -- Start a timer on the enemy instead of using tunnel:on_finished() to avoid continue if the enemy was disabled from outside this script.
  end)
end

-- Start leaps out the ground and fly.
function enemy:appear()

  -- Target a random point at the opposite side of the room.
  local region_x, region_y, _ =  camera:get_position()
  local region_width, region_height = camera:get_size()
  local angle_variance = math.random() * angle_amplitude_from_center * 2 - angle_amplitude_from_center
  local angle = enemy:get_angle(region_x + region_width / 2.0, region_y + region_height / 2.0) + angle_variance
  local movement = enemy:start_straight_walking(angle, jumping_speed)
  movement:set_smooth(false)

  -- Schedule an update of the head sprite vertical offset by frame.
  local duration = math.random(jumping_minimum_duration, jumping_maximum_duration)
  local elapsed_time = 0
  sol.timer.start(enemy, 10, function()

    update_body_sprites()
    elapsed_time = elapsed_time + 10
    if elapsed_time < duration then
      local progress = elapsed_time / duration
      head_sprite:set_xy(0, -(1.1 * math.sin(progress * math.pi) + 0.3 * math.sin(3 * progress * math.pi)) * jumping_height) -- Curve with two bumps.
      return true
    end
    if movement and enemy:get_movement() == movement then
      movement:stop()
    end
    enemy:disappear()
  end)

  -- Properties and effects.
  enemy:set_visible()
  enemy:set_obstacle_behavior("flying")
  update_sprites_direction(angle)
  update_sprites_order(angle)
  head_sprite:set_opacity(255)
  enemy:start_brief_effect("enemies/" .. enemy:get_breed() .. "/dust", "projections", 0, 0, tail_frame_lag * 10 + 150)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions("ignored", {
    sword = 1,
    thrust = 2,
    arrow = 4
  })
  enemy:set_can_attack(true)
end

-- Make enemy disappear in the ground.
function enemy:disappear()

  -- Start disappearing effects.
  enemy:start_brief_effect("enemies/" .. enemy:get_breed() .. "/dust", "projections", 0, 0, tail_frame_lag * 10 + 150)
  head_sprite:set_opacity(0)

  -- Continue an extra loop of last_positions update to make the whole body.
  local elapsed_frames = 0
  sol.timer.start(enemy, 10, function()
    update_body_sprites()
    elapsed_frames = elapsed_frames + 1
    if elapsed_frames < tail_frame_lag then
      return true
    end
    enemy:restart()
  end)
end

-- Wait a few time and appear.
function enemy:wait()

  sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    if not camera:overlaps(enemy:get_max_bounding_box()) then
      return true
    end
    enemy:start_tunneling()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(8)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 8)
  enemy:start_shadow()

  -- Create sprites.
  tail_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/tail")
  enemy:set_invincible_sprite(tail_sprite) -- TODO Never use this function and simulate the protected behavior instead of the ignored one.
  for i = 1, 5 do
    body_sprites[i] = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/body")
    enemy:set_invincible_sprite(body_sprites[i]) -- TODO Never use this function and simulate the protected behavior instead of the ignored one.
  end
  head_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- States.
  last_positions = {}
  frame_count = 0
  reset_sprites()
  enemy:set_visible(false)
  enemy:set_obstacle_behavior("flying")
  enemy:set_layer_independent_collisions(true)
  enemy:set_can_attack(false)
  enemy:set_damage(4)
  enemy:set_invincible()
  enemy:wait()
end)
