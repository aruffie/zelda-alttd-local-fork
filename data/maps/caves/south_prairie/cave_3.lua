-- Variables
local map = ...
local game = map:get_game()

-- Includes scripts
local mad_bat_manager = require("scripts/maps/mad_bat_manager")

-- Map events
function map:on_started()

  mad_bat_manager:init_map(map, "mad_bat", "mad_bat_3")

end