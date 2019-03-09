-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

function map:on_started()

  -- Music
  map:init_music()
  
  -- Sideview
  map.is_sideview=true
end

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("20_sidescrolling")

end