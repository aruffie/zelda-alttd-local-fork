-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local fairy_manager = require("scripts/maps/fairy_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  -- Fairy
  fairy_manager:init_map(map, "fairy")

end)

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("72_great_fairy_fountain")

end

-- NPCs events
function fairy_fountain:on_activated()

  fairy_manager:launch_fairy_if_hero_not_max_life(map, "fairy")

end