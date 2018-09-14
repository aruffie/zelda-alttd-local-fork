--Inside - Telephone booth 1

-- Variables
local map = ...
local game = map:get_game()

-- Includes scripts
local phone_manager = require("scripts/maps/phone_manager")


-- Methods - Functions

-- Initialize the music of the map
function map:init_music()

  if game:get_value("main_quest_step") == 3  then
    sol.audio.play_music("maps/out/sword_search")
  else
    sol.audio.play_music("maps/houses/telephone_booth")
  end

end

-- Map events

function map:on_started(destination)

  map:init_music()


end

function phone_interaction:on_interaction()

      phone_manager:talk(map)

end

-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end

