-- Global variables
local entity = ...
require("scripts/multi_events")

local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()
local sprite = entity:get_sprite()
local hurt_shader = sol.shader.create("hurt")
local circle = math.pi * 2.0
local quarter = math.pi * 0.5
local is_flying = false

-- Configuration variables.
local waiting_minimum_duration = 1250
local waiting_maximum_duration = 1750
local jumping_speed = 50
local jumping_duration = 200
local jumping_height = 4
local jumping_minimum_count = 1
local jumping_maximum_count = 8
local flying_speed = 80
local flying_duration = 1000
local flying_height = 16
local hurt_duration = 300

-- Create the shadow sprite below the enemy.
local function create_shadow()

  local shadow = entity:create_sprite("entities/shadows/shadow")
  entity:bring_sprite_to_back(shadow)
end

-- Start the enemy jumping movement.
local function start_jumping(duration, height, angle, speed, count, animation, on_finished_callback)

  local movement = sol.movement.create("straight")
  movement:set_speed(speed)
  movement:set_angle(angle)
  movement:set_smooth(false)
  movement:start(entity)
  sprite:set_animation(animation)
  sprite:set_direction((angle > quarter and angle < 3.0 * quarter) and 2 or 0)

  -- Schedule an update of the sprite vertical offset by frame.
  local elapsed_time = 0
  sol.timer.start(entity, 10, function()

    elapsed_time = elapsed_time + 10
    if elapsed_time < duration then
      sprite:set_xy(0, -math.sqrt(math.sin(elapsed_time / duration * math.pi)) * height)
      return true
    else
      sprite:set_xy(0, 0)
      if count > 1 then
        start_jumping(duration, height, angle, speed, count - 1, animation, on_finished_callback)
      else
        movement:stop()
        on_finished_callback()
      end
    end
  end)
end

-- Start flying away to the hero
local function start_flying(on_finished_callback)

  if is_flying then
    return
  end
  is_flying = true

  sol.timer.stop_all(entity)
  entity:stop_movement()

  sprite:set_shader(hurt_shader)
  sol.timer.start(entity, hurt_duration, function()
    sprite:set_shader(nil)
  end)

  start_jumping(flying_duration, flying_height, hero:get_angle(entity), flying_speed, 1, "flying", function()
    is_flying = false
    on_finished_callback()
  end)
end

-- Start waiting before jumping.
local function start_waiting()

  sprite:set_animation("waiting")
  sol.timer.start(entity, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    start_jumping(jumping_duration, jumping_height, math.random() * circle, jumping_speed, math.random(jumping_minimum_count, jumping_maximum_count), "jumping", start_waiting)
  end)
end

-- Initialize the entity.
entity:register_event("on_created", function()

  create_shadow()
  entity:set_drawn_in_y_order()
  start_jumping(jumping_duration, jumping_height, math.random() * circle, jumping_speed, math.random(jumping_minimum_count, jumping_maximum_count), "jumping", start_waiting)

  -- Start flying away from the hero when hurt by the sword.
  entity:add_collision_test("sprite", function(bird, entity, bird_sprite, entity_sprite)
    if entity == hero and entity_sprite == hero:get_sprite("sword") then
      start_flying(start_waiting)
    end
  end)
end)
