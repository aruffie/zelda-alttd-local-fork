-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local separator_manager = require("scripts/maps/separator_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  
end)

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("18_cave")

end

-- Doors events
function weak_door_1:on_opened()
  
  audio_manager:play_sound("misc/secret1")
  
end

-- Separators
separator_manager:init(map)