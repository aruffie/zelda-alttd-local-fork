-- Lua script of map caves/forest/cave_1.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()

local mad_bat_manager = require("scripts/maps/mad_bat_manager")

function map:on_started()


  mad_bat_manager:init_map(map, "mad_bat", "mad_bat_3")

end