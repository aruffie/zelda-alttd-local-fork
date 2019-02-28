-- Lua script of custom entity iron_ball.
-- This script is executed every time a custom entity with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local iron_ball = ...
local game = iron_ball:get_game()
local map = iron_ball:get_map()

iron_ball:register_event("on_created", function(iron_ball)

  -- General properties
  iron_ball:set_traversable_by(false)
  iron_ball:set_drawn_in_y_order(true)
  iron_ball:set_weight(2)

  -- Traversable rules
  iron_ball:set_can_traverse("hero", true)
  iron_ball:set_can_traverse("jumper", true)
  iron_ball:set_can_traverse("stairs", true)
  iron_ball:set_can_traverse("stream", true)
  iron_ball:set_can_traverse("switch", true)
  iron_ball:set_can_traverse("teletransporter", true)
  iron_ball:set_can_traverse_ground("deep_water", true)
  iron_ball:set_can_traverse_ground("shallow_water", true)
  iron_ball:set_can_traverse_ground("hole", true)
  iron_ball:set_can_traverse_ground("lava", true)
  iron_ball:set_can_traverse_ground("prickles", true)
  iron_ball:set_can_traverse_ground("low_wall", true)
  iron_ball:set_can_traverse(false)

  -- Behavior when carried
  iron_ball:register_event("on_lifting", function(iron_ball, hero, carried_iron_ball)

    -- Properties
    carried_iron_ball:set_damage_on_enemies(1)

    -- Behavior when breaking
    carried_iron_ball:register_event("on_breaking", function(carried_iron_ball)
      
      -- Call the hit_by_iron_ball() function on any entity that overlaps the iron_ball and implements the function
      for entity in map:get_entities_in_rectangle(carried_iron_ball:get_bounding_box()) do
        if entity.hit_by_iron_ball ~= nil then
          entity:hit_by_iron_ball()
        end
      end

      -- TODO Recreate the initial iron_ball when breaking, then change direction if a non-traversable tile/entity is hit and finally bounce on the ground
    end)
  end)
end)
