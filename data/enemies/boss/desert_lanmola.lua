----------------------------------
--
-- Desert Lanmola.
--
-- Caterpillar enemy that can have any number of body parts that will follow the head move.
-- Wait a few time then leaps out the ground, do a curved fly with two bump and dive into the ground again.
-- Don't restart on hurt to let the move end, and explode part by part on die.
--
-- Methods : enemy:start_tunneling()
--           enemy:appear()
--           enemy:disappear()
--           enemy:wait()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprites = {}
local last_positions, frame_count
local tunnel, appearing_dust, disappearing_dust

-- Configuration variables
local tied_sprites_frame_lags = {15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165, 180, 195, 210, 225, 240, 255, 270, 285, 300}
local tunnel_duration = 1000
local waiting_minimum_duration = 2000
local waiting_maximum_duration = 4000
local jumping_speed = 48
local jumping_height = 32
local jumping_minimum_duration = 2700
local jumping_maximum_duration = 3000
local angle_amplitude_from_center = math.pi * 0.125

-- Constants
local sprites_count = #tied_sprites_frame_lags + 1
local tail_frame_lag = tied_sprites_frame_lags[#tied_sprites_frame_lags]
local highest_frame_lag = tail_frame_lag + 1
local eighth = math.pi * 0.25
local sixteenth = math.pi * 0.125
local circle = math.pi * 2.0

-- Return a random visible position.
local function get_random_visible_position()

  local x, y, _ =  camera:get_position()
  local width, height = camera:get_size()
  return math.random(x, x + width), math.random(y, y + height)
end

-- Return a table with only visible sprites and without the head, sorted from tail to head.
function get_exploding_tied_sprites()

	local exploding_sprites = {}
  local i = 1
	for j = sprites_count, 2, -1 do
    local sprite = sprites[j]
    if sprite:get_opacity() ~= 0 then
  		exploding_sprites[i] = sprite
      i = i + 1
    end
	end
  return exploding_sprites
end

-- Remove dust and tunnel effects.
function remove_effects()

  local function remove_effect(effect)
    if effect and effect:exists() then
      effect:remove()
    end
  end
  remove_effect(tunnel)
  remove_effect(appearing_dust)
  remove_effect(disappearing_dust)
end

-- Set the given sprite visible or not, and exclude it from collision test with the hero if invisible.
local function set_sprite_visible(sprite, visible)

  local opacity = visible and 255 or 0
  if sprite:get_opacity() ~= opacity then
    sprite:set_opacity(opacity)
    if opacity == 0 then
      sprite:set_xy(0, 400) -- Workaround: No way to set sprites insensible to pixel-perfect collision when invisible, move them far away the origin on reset.
    end
  end
end

-- Update body and tail sprites depending on current and previous positions.
local function update_body_sprites()

  -- Save current head sprite position if it is still visible.
  local head_sprite = sprites[1]
  local x, y, _ = enemy:get_position()
  local x_offset, y_offset = head_sprite:get_xy()
  if head_sprite:get_opacity() ~= 0 then
    last_positions[frame_count] = {x = x + x_offset, y = y + y_offset}
  else
    last_positions[frame_count] = nil
  end

  -- Replace tied sprites on a previous position, making sprites with no position invisible.
  local function replace_part_sprite(sprite, frame_lag)
    local key = (frame_count - frame_lag) % highest_frame_lag
    set_sprite_visible(sprite, last_positions[key] ~= nil)
    if last_positions[key] then
      sprite:set_xy(last_positions[key].x - x, last_positions[key].y - y)
    end
  end
  for i = 2, sprites_count do
    replace_part_sprite(sprites[i], tied_sprites_frame_lags[i - 1])
  end

  frame_count = (frame_count + 1) % highest_frame_lag
end

-- Set the correct direction8 to all sprites depending on the given angle.
local function update_sprites_direction(angle)

  local direction8 = math.floor((angle + sixteenth) % circle / eighth)
  for _, sprite in pairs(sprites) do
    sprite:set_direction(direction8)
  end
end

-- Update all sprites z-order depending on the given moving angle.
local function update_sprites_order(angle)

  local head_on_front = angle > math.pi and angle < circle
  local order_method = head_on_front and enemy.bring_sprite_to_back or enemy.bring_sprite_to_front
  for _, sprite in ipairs(sprites) do
    order_method(enemy, sprite)
  end
end

-- Set the given animation on all enemy sprites.
local function set_sprites_animation(animation)

  for _, sprite in pairs(sprites) do
    sprite:set_animation(animation)
  end
end

-- Manually hurt the enemy to not restart it automatically and let it finish its move.
local function hurt(damage)

  -- Don't hurt if a previous hurt animation is still running.
  local head_sprite = sprites[1]
  if head_sprite:get_animation() == "hurt" then
    return
  end

  -- Die if no more life.
  local remaining_life = enemy:get_life() - damage
  if enemy:get_life() - damage < 1 then
    set_sprites_animation("hurt")
    remove_effects()
    enemy:stop_all()
    
    -- Wait a few time, make visible tied sprites explode from tail to head, wait a few time again and finally make the head explode and enemy die.
    sol.timer.start(enemy, 2000, function()
      enemy:start_sprite_explosions(get_exploding_tied_sprites(), "entities/explosion_boss",function()
        sol.timer.start(enemy, 500, function()
          local x, y = head_sprite:get_xy()
          enemy:start_brief_effect("entities/explosion_boss", nil, x, y)
          enemy:silent_kill(-y)
        end)
      end)
    end)
    return
  end

  -- Manually hurt else to not trigger the built-in behavior.
  enemy:set_life(enemy:get_life() - damage)
  set_sprites_animation("hurt")
  sol.timer.start(enemy, 1000, function()
    set_sprites_animation("walking")
  end)
  if enemy.on_hurt then
    enemy:on_hurt()
  end
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
  tunnel = enemy:start_brief_effect("enemies/" .. enemy:get_breed() .. "/dust", "tunnel", 0, 0, tunnel_duration)
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

  -- Schedule an update of the head sprite vertical offset by frame.
  local head_sprite = sprites[1]
  local duration = math.random(jumping_minimum_duration, jumping_maximum_duration)
  local elapsed_time = 0
  sol.timer.start(enemy, 10, function()

    update_body_sprites()
    elapsed_time = elapsed_time + 10
    if elapsed_time < duration then
      local progress = elapsed_time / duration
      head_sprite:set_xy(0, -(0.913 * math.sqrt(math.sin(progress * math.pi)) + 0.35 * math.sin(math.sin(3 * progress * math.pi))) * jumping_height) -- Curve with two bumps.
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
  appearing_dust = enemy:start_brief_effect("enemies/" .. enemy:get_breed() .. "/dust", "projections", 0, 0, tail_frame_lag * 10 + 150)
  appearing_dust:bring_to_back()

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions("ignored", {
    sword = function() hurt(1) end,
    thrust = function() hurt(2) end,
    arrow = function() hurt(4) end
  })
  enemy:set_can_attack(true)
end

-- Make enemy disappear in the ground.
function enemy:disappear()

  -- Start disappearing effects.
  local head_sprite = sprites[1]
  head_sprite:set_opacity(0)
  disappearing_dust = enemy:start_brief_effect("enemies/" .. enemy:get_breed() .. "/dust", "projections", 0, 0, tail_frame_lag * 10 + 150)
  disappearing_dust:bring_to_back()
  enemy:set_invincible()

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

-- Remove effects on disabled.
enemy:register_event("on_disabled", function(enemy)
  remove_effects()
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(8)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()

  -- Create sprites.
  sprites[1] = enemy:create_sprite("enemies/" .. enemy:get_breed())
  for i = 2, sprites_count - 1 do
    sprites[i] = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/body")
    enemy:set_invincible_sprite(sprites[i]) -- TODO Never use this function and simulate the protected behavior instead of the ignored one.
  end
  sprites[sprites_count] = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/tail")
  enemy:set_invincible_sprite(sprites[sprites_count]) -- TODO Never use this function and simulate the protected behavior instead of the ignored one.
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- States.
  last_positions = {}
  frame_count = 0
  for _, sprite in pairs(sprites) do
    set_sprite_visible(sprite, false)
  end
  enemy:stop_movement()
  enemy:set_visible(false)
  enemy:set_obstacle_behavior("flying")
  enemy:set_layer_independent_collisions(true)
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_can_attack(false)
  enemy:set_damage(4)
  enemy:set_invincible()
  enemy:wait()
end)
