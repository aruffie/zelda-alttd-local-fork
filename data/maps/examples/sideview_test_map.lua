-- Lua script of map examples/sideview_test_map.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...

-- Event called at initialization time, as soon as this map is loaded.
local separator_manager=require("scripts/maps/separator_manager")
function map:on_started()
  separator_manager:init(map)
  map:set_sideview(true)
end 