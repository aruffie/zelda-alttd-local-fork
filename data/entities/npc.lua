-- Lua script of custom entity npc.
-- This script is executed every time a custom entity with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
require("scripts/multi_events")
--entity:set_traversable_by("hero", false)

function entity:on_created()
  print "Custom NPC was successfully created"
end

entity:register_event("on_interaction", function()
    print "Interacting with a custom NPC"
    local dialog=entity:get_property("dialog")
    if dialog then 
      game:start_dialog(dialog)
    end
  end)