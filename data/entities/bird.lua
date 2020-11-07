-- Global variables
local entity = ...
require("scripts/multi_events")

local game = entity:get_game()
local map = entity:get_map()
local sprite = entity:get_sprite()
local circle = math.pi * 2.0
local quarter = math.pi * 0.5

-- Configuration variables.
local waiting_minimum_duration = 1250
local waiting_maximum_duration = 1750
local jumping_speed = 50
local jumping_duration = 200
local jumping_height = 4
local jumping_minimum_count = 1
local jumping_maximum_count = 8

-- Create the shadow sprite below the enemy.
local function create_shadow()

  local shadow = entity:create_sprite("entities/shadows/shadow")
  entity:bring_sprite_to_back(shadow)
end

-- Start flying away to the hero
local function start_flying()

  -- TODO Fly away on hurt by the hero.
end

-- Start the enemy jumping movement.
local function start_jumping(angle, count, on_finished_callback)

  local movement = sol.movement.create("straight")
  movement:set_speed(jumping_speed)
  movement:set_angle(angle)
  movement:set_smooth(false)
  movement:start(entity)
  sprite:set_animation("jumping")
  sprite:set_direction((angle > quarter and angle < 3.0 * quarter) and 2 or 0)

  -- Schedule an update of the sprite vertical offset by frame.
  local elapsed_time = 0
  sol.timer.start(entity, 10, function()

    elapsed_time = elapsed_time + 10
    if elapsed_time < jumping_duration then
      sprite:set_xy(0, -math.sqrt(math.sin(elapsed_time / jumping_duration * math.pi)) * jumping_height)
      return true
    else
      sprite:set_xy(0, 0)
      if count > 1 then
        start_jumping(angle, count - 1, on_finished_callback)
      else
        movement:stop()
        on_finished_callback()
      end
    end
  end)
end

-- Start waiting before jumping.
local function start_waiting()

  sprite:set_animation("waiting")
  sol.timer.start(entity, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    start_jumping(math.random() * circle, math.random(jumping_minimum_count, jumping_maximum_count), start_waiting)
  end)
end

-- Initialize the entity.
entity:register_event("on_created", function()

  create_shadow()
  start_jumping(math.random() * circle, math.random(jumping_minimum_count, jumping_maximum_count), start_waiting)
end)
