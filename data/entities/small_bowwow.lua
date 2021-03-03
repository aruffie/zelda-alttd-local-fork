-- Global variables
local entity = ...
local audio_manager = require("scripts/audio_manager")
require("scripts/multi_events")

local game = entity:get_game()
local map = entity:get_map()
local sprite = entity:get_sprite()
local circle = math.pi * 2.0

-- Configuration variables.
local waiting_minimum_duration = 1250
local waiting_maximum_duration = 1750
local jumping_speed = 50
local jumping_duration = 200
local jumping_height = 4
local jumping_minimum_count = 4
local jumping_maximum_count = 6

-- Create the shadow sprite below the enemy.
local function create_shadow()

  local shadow = entity:create_sprite("entities/shadows/shadow")
  entity:bring_sprite_to_back(shadow)
end

-- Start the enemy jumping movement.
local function start_jumping(angle, count, on_finished_callback)

  local movement = sol.movement.create("straight")
  movement:set_speed(jumping_speed)
  movement:set_angle(angle)
  movement:set_smooth(false)
  movement:start(entity)
  sprite:set_animation("jumping")
  sprite:set_direction(movement:get_direction4())

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
  entity:set_drawn_in_y_order()
  start_jumping(math.random() * circle, math.random(jumping_minimum_count, jumping_maximum_count), start_waiting)

  -- Workaround : Create a welded npc welded to the entity to trigger the action command on the hud when facing the entity.
  local x, y, layer = entity:get_position()
  local width, height = entity:get_size()
  local npc = map:create_npc({
    direction = 0,
    x = x,
    y = y,
    layer = layer,
    subtype = 1,
    width = width,
    height = height
  })
  npc:set_traversable(true)
  entity:register_event("on_position_changed", function(entity, x, y, layer)
    npc:set_position(x, y, layer)
  end)
  entity:register_event("on_removed", function(entity)
    if npc:exists() then
      npc:remove()
    end
  end)
  entity:register_event("on_enabled", function(entity)
    npc:set_enabled()
  end)
  entity:register_event("on_disabled", function(entity)
    npc:set_enabled(false)
  end)
end)


-- Create an exclamation symbol near enemy
function entity:create_symbol_exclamation(sound)

  local map = self:get_map()
  local x, y, layer = self:get_position()
  if sound then
    audio_manager:play_sound("menus/menu_select")
  end
  local symbol = map:create_custom_entity({
      sprite = "entities/symbols/exclamation",
      x = x - 16,
      y = y - 16,
      width = 16,
      height = 16,
      layer = layer + 1,
      direction = 0
    })

  return symbol

end
