-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local light_manager = require("scripts/maps/light_manager")

-- Map events
function map:on_started(destination)

  -- Music
  map:init_music()
  -- Light
  light_manager:init(map)
  map:set_light(0)

end

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("51_house_by_the_bay")

end

-- NPCs events
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end

