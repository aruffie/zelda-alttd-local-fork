-- Lua script of item "fairy".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Event called when the game is initialized.
function item:on_created()

  item:set_shadow(nil)
  item:set_can_disappear(true)
  item:set_brandish_when_picked(false)
  
end

-- Event called when a pickable treasure representing this item
-- is created on the map.
function item:on_pickable_created(pickable)

  -- Create a movement that goes into random directions,
  -- with a speed of 28 pixels per second.
  local movement = sol.movement.create("random")
  movement:set_speed(28)
  movement:set_ignore_obstacles(true)
  movement:set_max_distance(40)  -- Don't go too far.

  -- Put the fairy on the highest layer to show it above all walls.
  local x, y = pickable:get_position()
  pickable:set_position(x, y, 2)
  pickable:set_layer_independent_collisions(true)  -- But detect collisions with lower layers anyway

  -- When the direction of the movement changes,
  -- update the direction of the fairy's sprite
  function pickable:on_movement_changed(movement)

    if pickable:get_followed_entity() == nil then
      local sprite = pickable:get_sprite()
      local angle = movement:get_angle()  -- Retrieve the current movement's direction.
      if angle >= math.pi / 2 and angle < 3 * math.pi / 2 then
        sprite:set_direction(1)  -- Look to the left.
      else
        sprite:set_direction(0)  -- Look to the right.
      end
    end
  end
  movement:start(pickable)
  
end

-- Obtaining a fairy.
function item:on_obtaining(variant, savegame_variable)

  if item:get_game():get_life() == item:get_game():get_max_life() then
    audio_manager:play_sound("items/get_item2")
  else
    item:get_game():add_life(7 * 4)
  end

end

