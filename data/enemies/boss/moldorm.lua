----------------------------------
--
-- Moldorm.
--
-- Caterpillar enemy with three body parts and one tail that will follow the head move.
-- Moves in curved motion, and randomly change the direction of the curve.
-- Speed up the move if set_angry() or hurt.
--
-- Methods : enemy:start_walking()
--           enemy:set_angry()
--
----------------------------------

-- Global variables
local enemy = ...
local common_actions = require("enemies/lib/common_actions")
require("scripts/multi_events")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local head_sprite, tail_sprite
local body_sprites = {}
local last_positions, frame_count
local walking_movement = nil
local sixteenth = math.pi * 0.125
local eighth = math.pi * 0.25
local quarter = math.pi * 0.5
local circle = math.pi * 2.0

-- Configuration variables
local walking_speed = 88
local walking_angle = 0.035
local running_speed = 186
local body_frame_lags = {20, 35, 50}
local tail_frame_lag = 62
local keeping_angle_duration = 1000
local angry_duration = 3000
local before_explosion_delay = 2000
local between_explosion_delay = 500

local highest_frame_lag = tail_frame_lag + 1 -- Avoid too much values in the last_positions table

-- Hurt or repulse the hero depending on touched sprite.
local function on_attack_received()

  -- Make sure to only trigger this event once by attack.
  enemy:set_invincible()

  -- Hurt if hero sword sprite collide with the tail sprite.
  if enemy:overlaps(hero, "sprite", tail_sprite, hero:get_sprite("sword")) then
    if enemy:get_life() > 1 then
      enemy:hurt(1)
    else
      local ordered_sprites = {tail_sprite, body_sprites[3], body_sprites[2], body_sprites[1], head_sprite}
      for _, sprite in pairs(ordered_sprites) do
        if sprite:has_animation("hurt") then
          sprite:set_animation("hurt")
        end
      end
      enemy:stop_all()
      sol.timer.start(enemy, 2000, function()
        enemy:start_sprite_explosions(get_exploding_sprites(), "entities/explosion_boss", function()
          enemy:silent_kill()
        end)
      end)
    end
  else
    enemy:start_pushing_back(hero, 200, 100, function()
      enemy:set_hero_weapons_reactions(on_attack_received, {jump_on = "ignored"})
    end)
  end
end

-- Start the enemy movement.
function enemy:start_walking()

  walking_movement = sol.movement.create("straight")
  walking_movement:set_speed(walking_speed)
  walking_movement:set_angle(math.random(4) * quarter)
  walking_movement:set_smooth(false)
  walking_movement:start(enemy)

  -- Take the obstacle normal as angle on obstacle reached.
  function walking_movement:on_obstacle_reached()
    walking_movement:set_angle(enemy:get_obstacles_normal_angle())
  end

  -- Slightly change the angle when walking.
  function walking_movement:on_position_changed()
    local angle = walking_movement:get_angle() % circle
    if walking_movement == enemy:get_movement() then
      walking_movement:set_angle(angle + walking_angle)
    end
  end

  -- Regularly and randomly change the angle.
  sol.timer.start(enemy, keeping_angle_duration, function()
    if math.random(2) == 1 then
      walking_angle = 0 - walking_angle
    end
    return true
  end)
end

-- Increase the enemy speed for some time.
function enemy:set_angry()

  walking_movement:set_speed(running_speed)
  sol.timer.start(enemy, angry_duration, function()
    walking_movement:set_speed(walking_speed)
  end)
end

-- Update head, body and tails sprite on position changed whatever the movement is.
enemy:register_event("on_position_changed", function(enemy)

  if not last_positions then
    return -- Workaround : Avoid this event to be called before enemy is actually started by the engine.
  end

  -- Save current position
  local x, y, _ = enemy:get_position()
  last_positions[frame_count] = {x = x, y = y}

  -- Set the head sprite direction.
  local direction8 = math.floor((enemy:get_movement():get_angle() + sixteenth) % circle / eighth)
  if head_sprite:get_direction() ~= direction8 then
    head_sprite:set_direction(direction8)
  end

  -- Replace part sprites on a previous position.
  local function replace_part_sprite(sprite, frame_lag)
    local previous_position = last_positions[(frame_count - frame_lag) % highest_frame_lag] or last_positions[0]
    sprite:set_xy(previous_position.x - x, previous_position.y - y)
  end
  for i = 1, 3 do
    replace_part_sprite(body_sprites[i], body_frame_lags[i])
  end
  replace_part_sprite(tail_sprite, tail_frame_lag)

  frame_count = (frame_count + 1) % highest_frame_lag
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  common_actions.learn(enemy, sprite)
  enemy:set_life(4)
  enemy:set_size(32, 32)
  enemy:set_origin(16, 16)
  
  -- Create sprites in right z-order.
  tail_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/tail")
  for i = 3, 1, -1 do
    body_sprites[i] = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/body_" .. i)
  end
  head_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(on_attack_received, {jump_on = "ignored"})

  -- States.
  last_positions = {}
  frame_count = 0
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:start_walking()
  if enemy:get_life() < 4 then
    enemy:set_angry()
  end
end)
