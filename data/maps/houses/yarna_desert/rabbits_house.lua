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

end)

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("12_house")

end

-- Discussion with rabbit
function map:talk_to_rabbit()

  game:start_dialog("maps.houses.yarna_desert.rabbits_house.rabbit_1")

end

-- NPCs events
function rabbit:on_interaction()

  map:talk_to_rabbit()

end
