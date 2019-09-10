-- Lua script of custom entity pickable_sink.
-- This script is executed every time a custom entity with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local item, variant, savegame_variable
local timer

require("scripts/multi_events")
-- Event called when the custom entity is initialized.

entity:register_event("on_created", function(entity)
    -- Initialize the properties of your custom entity here,
    -- like the sprite, the size, and whether it can traverse other
    -- entities and be traversed by them.
    entity:add_collision_test("touching", function(entity, other)

        if other:get_type()=="hero" then
          item:on_obtaining(variant, savegame_variable)
          entity:remove()
        end
      end)

    function entity.set_item(_item, _variant, _savegame_variable)
--      print("in custom pickable script, getting the item infos. item=".._item:get_name()..", variant=".._variant..", savegame variable="..(_savegame_variable or "<none>"))
      item=_item
      variant=_variant
      variable=_savegame_variable

      if item:get_can_disappear() then --Self-destroy after 10 seconds
        --TODO add blinking effect 
        timer=sol.timer.start(entity, 10000, function()
            entity:remove()
          end)
      end

    end
    local visible=true
    entity:register_event("on_draw", function()
        if timer and timer:get_remaining_time() <= 3000 then
          visible=not visible
          entity:set_visible(visible)
        end
      end)
  end)


