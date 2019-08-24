-- Lua script of enemy mini_moldorm.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
local common_actions = require("enemies/lib/common_actions")
require("scripts/multi_events")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local head_sprite, body_sprite, tail_sprite
local last_positions, frame_count
local eighth = math.pi * 0.25
local quarter = math.pi * 0.5

-- Configuration variables
local walking_speed = 88
local walking_angle = 0.05
local body_frame_lag = 11
local tail_frame_lag = 20
local keeping_angle_maximum_duration = 1000

local highest_frame_lag = tail_frame_lag + 1 -- Avoid too much values in the last_positions table

-- Start a random straight movement of a random distance vertically or horizontally, and loop it without delay.
function enemy:start_walking()

  local movement = sol.movement.create("straight")
  movement:set_speed(walking_speed)
  movement:set_angle(math.random(4) * quarter)
  movement:set_smooth(false)
  movement:start(self)

  -- Inverse the angle on obstacle reached.
  function movement:on_obstacle_reached()
    movement:set_angle(movement:get_angle() + math.pi)
  end

  -- Regularly and randomly change the angle.
  sol.timer.start(enemy, keeping_angle_maximum_duration, function()
    if math.random(2) == 1 then
      walking_angle = 0 - walking_angle
    end
    return true
  end)
end

-- Replace body and tails sprite on position changed.
enemy:register_event("on_position_changed", function(enemy)

  local movement = enemy:get_movement()
  local angle = movement:get_angle() % (2.0 * math.pi)
  movement:set_angle(angle + walking_angle)

  -- Save current position
  local x, y, _ = enemy:get_position()
  last_positions[frame_count % highest_frame_lag] = {x = x, y = y}

  -- Set the head sprite direction.
  local direction8 = math.floor((angle + eighth / 4.0) % (2.0 * math.pi) / eighth)
  if head_sprite:get_direction() ~= direction8 then
    head_sprite:set_direction(direction8)
  end

  -- Replace part sprites on a previous position.
  local function replace_part_sprite(sprite, frame_lag)
    local previous_position = last_positions[(frame_count - frame_lag) % highest_frame_lag]
    if not previous_position then
      previous_position = last_positions[0]
    end
    sprite:set_xy(previous_position.x - x, previous_position.y - y)
  end
  replace_part_sprite(body_sprite, body_frame_lag)
  replace_part_sprite(tail_sprite, tail_frame_lag)

  frame_count = frame_count + 1
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  common_actions.learn(enemy, sprite)
  enemy:set_life(2)
  
  -- Create sprites.
  head_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  body_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/body")
  tail_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/tail")
  enemy:bring_sprite_to_back(body_sprite)
  enemy:bring_sprite_to_back(tail_sprite)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_attack_consequence("thrown_item", 2)
  enemy:set_attack_consequence("hookshot", 2)
  enemy:set_attack_consequence("sword", 1)
  enemy:set_attack_consequence("arrow", 2)
  enemy:set_attack_consequence("boomerang", 2)
  enemy:set_attack_consequence("explosion", 2)
  enemy:set_hammer_reaction(2)
  enemy:set_fire_reaction(2)

  -- States.
  last_positions = {}
  frame_count = 0
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking()
end)
