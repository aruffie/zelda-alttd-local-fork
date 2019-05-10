-- Variables
local map = ...
local game = map:get_game()
local hero_has_already_talk = false

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Map events
function map:on_started(destination)

  -- Music
  map:init_music()
  
end

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("14_shop")

end

-- Discussion with Monique
function  map:talk_to_crazy_tracy()
  
  if not hero_has_already_talk then
    game:start_dialog("maps.houses.graveyard.drugstore.crazy_tracy_1", function()
      hero_has_already_talk = true
    end)
  else
    game:start_dialog("maps.houses.graveyard.drugstore.crazy_tracy_2", function(answer)
      if answer then
      else
        game:start_dialog("maps.houses.graveyard.drugstore.crazy_tracy_7")
      end
      hero_has_already_talk = false
    end)
  end
  

end

-- NPCs events

function crazy_tracy:on_interaction()

  map:talk_to_crazy_tracy()

end

-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end
