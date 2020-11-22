-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")


-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  -- Digging
  map:set_digging_allowed(true)
  
  -- Make areas invisible.
  mask_shrine_area_1:set_visible(false)
  mask_shrine_area_2:set_visible(false)
end)

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("10_overworld")

end

-- Doors events
function weak_door_1:on_opened()
  
  audio_manager:play_sound("misc/secret1")
  
end