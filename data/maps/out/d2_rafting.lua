-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
local audio_manager = require("scripts/audio_manager")


-- Map events
function map:on_started()

  -- Music
  map:init_music()
  -- Digging
  map:set_digging_allowed(true)

end

-- Initialize the music of the map
function map:init_music()

  -- Todo add music rafting

end