-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local separator_manager = require("scripts/maps/separator_manager")
local audio_manager = require("scripts/audio_manager")

map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  -- Entities
  map:init_map_entities()

end)

-- Initialize the music of the map
function map:init_music()
  
  audio_manager:play_music("37_dream_shrine")

end

-- Initializes Entities based on player's progress
function map:init_map_entities()

  -- Hero
  hero:set_enabled(true)
  
end

-- Separators
separator_manager:init(map)