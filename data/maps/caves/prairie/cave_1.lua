-- Variables
local map = ...
local game = map:get_game()

-- Includes scripts
local separator_manager = require("scripts/maps/separator_manager")


--Doors events
function weak_door_1:on_opened()
  sol.audio.play_sound("secret_1")
end

separator_manager:manage_map(map)

