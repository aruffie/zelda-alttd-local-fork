-- Variables
local map = ...
local game = map:get_game()

-- Includes scripts
local mad_bat_manager = require("scripts/maps/mad_bat_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events
function map:on_started(destination)

  -- Music
  map:init_music()
    -- Mad bat
  mad_bat_manager:init_map(map, "mad_bat", "mad_bat_2")
  
end

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("18_cave")

end