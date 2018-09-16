--Inside - Telephone booth 4

-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
function map:init_music()
local phone_manager = require("scripts/maps/phone_manager")


-- Methods - Functions

-- Events

function map:on_started()

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

