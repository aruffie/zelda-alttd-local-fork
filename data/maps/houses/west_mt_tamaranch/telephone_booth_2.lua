-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
local phone_manager = require("scripts/maps/phone_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events
function map:on_started(destination)

  -- Music
  map:init_music()
  
end

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("13_phone")

end

-- NPCs events
function phone_interaction:on_interaction()

  phone_manager:talk(map)

end

-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end