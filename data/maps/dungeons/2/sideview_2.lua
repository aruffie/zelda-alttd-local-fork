
-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local separator_manager = require("scripts/maps/separator_manager")

-- Map events
function map:on_started()

  -- Music
  map:init_music()
  -- Sideview
  map:set_sideview(true)
  -- Separators
  separator_manager:init(map)

end

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("20_sidescrolling")

end