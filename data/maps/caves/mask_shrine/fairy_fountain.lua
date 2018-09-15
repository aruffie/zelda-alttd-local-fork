-- Variables
local map = ...
local game = map:get_game()

-- Includes scripts
local fairy_manager = require("scripts/maps/fairy_manager")

-- Map events
function map:on_started()

  fairy_manager:init_map(map, "fairy")

end


