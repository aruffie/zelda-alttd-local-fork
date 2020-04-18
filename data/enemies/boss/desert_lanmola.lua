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
local appearing_projections, disappearing_projections
local is_under_ground

-- Configuration variables
local tunnel_duration = 1000
local waiting_minimum_duration = 2000
local waiting_maximum_duration = 4000
local jumping_speed = 48
local jumping_height = 32
local jumping_minimum_duration = 2500
local jumping_maximum_duration = 3500
local body_frame_lags = {20, 35, 50, 65, 80}
local tail_frame_lag = 95
local angle_amplitude_from_center = sixteenth

local highest_frame_lag = tail_frame_lag + 1 -- Avoid too much values in the last_positions table

-- Return a random visible position.
local function get_random_visible_position()

  local x, y, _ =  camera:get_position()
  local width, height = camera:get_size()
  return math.random(x, x + width), math.random(y, y + height)
end

-- Update body sprites depending on current and previous positions.
local function update_body()

  -- Save current position if the enemy still moves.
  local x, y, _ = enemy:get_position()
  local x_offset, y_offset = head_sprite:get_xy()
  if enemy:get_movement() then
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

-- Update sprite z-order depending on the enemy moving angle.
local function update_sprites_order(angle)

  local head_on_front = angle > math.pi and angle < circle
  local order_method = head_on_front and enemy.bring_sprite_to_front or enemy.bring_sprite_to_back

  order_method(enemy, tail_sprite)
  for i = 5, 1, -1 do
    order_method(enemy, body_sprites[i])
  end
  order_method(enemy, head_sprite)
end

-- Set the correct direction to all enemy sprites depeding on the given angle.
local function update_sprites_direction(angle)

  local direction8 = math.floor((enemy:get_movement():get_angle() + sixteenth) % circle / eighth)

  tail_sprite:set_direction(direction8)
  for i = 5, 1, -1 do
    body_sprites[i]:set_direction(direction8)
  end
  head_sprite:set_direction(direction8)
end

-- Make the enemy appear at a random position.
function enemy:appear()

  -- Postpone to the next frame if the random position would be over an obstacle.
  local x, y, _ = enemy:get_position()
  local random_x, random_y = get_random_visible_position()
  if enemy:test_obstacles(random_x - x, random_y - y) then
    sol.timer.start(enemy, 10, function()
      enemy:appear()
    end)
    return
  end

  enemy:set_position(random_x, random_y)
  local tunnel = enemy:start_brief_effect("enemies/" .. enemy:get_breed() .. "/dust", "tunnel", 0, 0, tunnel_duration, function()

    is_under_ground = false
    appearing_projections = enemy:start_brief_effect("enemies/" .. enemy:get_breed() .. "/dust", "projections", 0, 0, appariton_duration)
    enemy:set_visible()
    enemy:start_rushing()
    head_sprite:set_opacity(255)

    -- Behavior for each items.
    enemy:set_hero_weapons_reactions(1, {jump_on = "ignored"})
    enemy:set_can_attack(true)
  end)
end

-- Start rush out the sand and fly.
function enemy:start_rushing()

  -- Target a random point at the opposite side of the room.
  local region_x, region_y, _ =  camera:get_position()
  local region_width, region_height = camera:get_size()
  local angle_variance = math.random() * angle_amplitude_from_center * 2 - angle_amplitude_from_center
  local angle = enemy:get_angle(region_x + region_width / 2.0, region_y + region_height / 2.0) + angle_variance
  local movement = enemy:start_straight_walking(angle, jumping_speed)

  -- Schedule an update of the head sprite vertical offset by frame.
  local duration = math.random(jumping_minimum_duration, jumping_maximum_duration)
  local elapsed_time = 0
  sol.timer.start(enemy, 10, function()

    elapsed_time = elapsed_time + 10
    if elapsed_time < duration then
      local progress = elapsed_time / duration
      head_sprite:set_xy(0, -(1.1 * math.sin(progress * math.pi) + 0.3 * math.sin(3 * progress * math.pi)) * jumping_height) -- Curve with two bumps.
      return true
    else
      head_sprite:set_xy(0, 0)
      if movement and enemy:get_movement() == movement then
        movement:stop()
      end

      -- Start disappearing effects, the real disparition is made when the tail sprite will be under ground.
      disappearing_projections = enemy:start_brief_effect("enemies/" .. enemy:get_breed() .. "/dust", "projections")
      head_sprite:set_opacity(0)
    end
  end)
  enemy:set_obstacle_behavior("flying")
  update_sprites_direction(angle)
  update_sprites_order(angle)
end

-- Wait a few time and appear.
function enemy:wait()

  sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    if not camera:overlaps(enemy:get_max_bounding_box()) then
      return true
    end
    enemy:appear()
  end)
end

-- Passive behaviors needing constant checking.
enemy:register_event("on_update", function(enemy)

  if enemy:is_immobilized() then
    return
  end

  if not is_under_ground then
    update_body()

-- TODO Do it on a custom tail_sprite:on_out_of_ground() event
    -- Removes projections if the head and tails sprites are both visible.
    if appearing_projections and appearing_projections:exists() and head_sprite:get_opacity() ~= 0 and tail_sprite:get_opacity() ~= 0 then
      appearing_projections:remove()
    end

--TODO Make a enemy:disappear() function that will just finish an extra loop of last_position update
    -- Reset the enemy and consider it as under groud if both head and tail sprites are invisible.
    if head_sprite:get_opacity() == 0 and tail_sprite:get_opacity() == 0 then
      is_under_ground = true
      if disappearing_projections and disappearing_projections:exists() then
        disappearing_projections:remove()
      end
      enemy:restart()
    end
  end
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()

  -- Create sprites.
  tail_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/tail")
  for i = 5, 1, -1 do
    body_sprites[i] = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/body")
  end
  head_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- States.
  is_under_ground = true
  last_positions = {}
  frame_count = 0
  enemy:set_visible(false)
  enemy:set_can_attack(false)
  enemy:set_damage(2)
  enemy:set_invincible()
  enemy:wait()
end)
