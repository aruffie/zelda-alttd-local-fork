-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

-- Map events
map:register_event("on_started", function(map, destination)

print ("(on_started) starting map starting map "..map:get_id()..",  direction", hero:get_direction())
  -- Music
  map:init_music()
  
end)

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("18_cave")

end