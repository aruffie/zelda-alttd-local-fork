-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")
local separator_manager = require("scripts/maps/separator_manager")

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  
end)

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("18_cave")

end