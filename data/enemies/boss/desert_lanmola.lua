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
local quarter = math.pi * 0.5
local sixteenth = math.pi * 0.125

-- Configuration variables
local tunnel_duration = 1000
local waiting_minimum_duration = 2000
local waiting_maximum_duration = 4000
local jumping_speed = 32
local jumping_height = 32
local jumping_minimum_duration = 3000
local jumping_maximum_duration = 4000
local angle_amplitude_from_center = sixteenth

-- Return a random visible position.
local function get_random_visible_position()

  local x, y, _ =  camera:get_position()
  local width, height = camera:get_size()

  return math.random(x, x + width), math.random(y, y + height)
end

-- Update body sprites offset depending on previous positions.
local function update_body()

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

    local projections = enemy:start_brief_effect("enemies/" .. enemy:get_breed() .. "/dust", "projections", 0, 0, appariton_duration)
    enemy:set_visible()
    enemy:start_rushing()

    -- Behavior for each items.
    enemy:set_hero_weapons_reactions(1, {jump_on = "ignored"})
    enemy:set_can_attack(true)
  end)
end

-- Make the enemy dive into the ground and disappear.
function enemy:disappear()

  local projections = enemy:start_brief_effect("enemies/" .. enemy:get_breed() .. "/dust", "projections")
  enemy:restart()
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
      head_sprite:set_xy(0, -(math.sqrt(math.sqrt(math.sin(progress * math.pi))) - 0.15 * math.sin(progress * math.pi) + 0.15 * math.sin(5 * progress * math.pi)) * jumping_height)
      return true
    else
      head_sprite:set_xy(0, 0)
      if movement and enemy:get_movement() == movement then
        movement:stop()
      end
      enemy:disappear()
    end
  end)
  enemy:set_obstacle_behavior("flying")
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
  enemy:set_visible(false)
  enemy:set_can_attack(false)
  enemy:set_damage(2)
  enemy:set_invincible()
  enemy:wait()
end)
