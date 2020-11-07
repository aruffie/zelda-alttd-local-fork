-- Global variables
local entity = ...
require("scripts/multi_events")

local game = entity:get_game()
local map = entity:get_map()
local sprite = entity:get_sprite()
local eighth = math.pi * 0.25

-- Configuration variables.
local waiting_minimum_duration = 500
local waiting_maximum_duration = 1500
local jumping_angles = {0, eighth, 2.0 * eighth, 3.0 * eighth, 4.0 * eighth, 5.0 * eighth, 6.0 * eighth, 7.0 * eighth}
local jumping_speed = 50
local jumping_maximum_duration = 500
local jumping_maximum_height = 12

-- Create the shadow sprite below the enemy.
local function create_shadow()

  local shadow = entity:create_sprite("entities/shadows/shadow")
  entity:bring_sprite_to_back(shadow)
end

-- Start the entity jump movement.
local function start_jumping(on_finished_callback)

  local direction4 = math.random(8)
  local movement = sol.movement.create("straight")
  movement:set_speed(jumping_speed)
  movement:set_angle(jumping_angles[direction4])
  movement:set_smooth(false)
  movement:start(entity)
  sprite:set_animation("jumping")
  sprite:set_direction(movement:get_direction4())

  -- Schedule an update of the sprite vertical offset by frame.
  local elapsed_time = 0
  local jumping_strength = math.random() % 0.5 + 0.5 -- The jump is on a random strength, use the same ratio for height and duration.
  local duration = jumping_maximum_duration * jumping_strength
  local height = jumping_maximum_height * jumping_strength
  sol.timer.start(entity, 10, function()

    elapsed_time = elapsed_time + 10
    if elapsed_time < duration then
      sprite:set_xy(0, -math.sqrt(math.sin(elapsed_time / duration * math.pi)) * height)
      return true
    else
      sprite:set_xy(0, 0)
      movement:stop()
      on_finished_callback()
    end
  end)
end

-- Start waiting before jumping.
local function start_waiting()

  sprite:set_animation("waiting")
  sol.timer.start(entity, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    start_jumping(start_waiting)
  end)
end

-- Initialize the entity.
entity:register_event("on_created", function()

  create_shadow()
  entity:set_drawn_in_y_order()
  start_waiting()
end)
