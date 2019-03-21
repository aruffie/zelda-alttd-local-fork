-- Lua script of map examples/sideview_test_map.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...

-- Event called at initialization time, as soon as this map is loaded.

function map:on_started()
  map:set_sideview(true)
--  sol.timer.start(self, 10, function()
--      for entity in map:get_entities() do
--        local x,y=entity:get_position()
--        if not entity:test_obstacles(0,1) then
--          entity:set_position(x,y+1)
--        end
--      end
--      return true
--    end)
end 