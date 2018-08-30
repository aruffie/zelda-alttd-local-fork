--Inside - Telephone booth 8

-- Variables
local map = ...
local game = map:get_game()

-- Includes scripts
local phone_manager = require("scripts/maps/phone_manager")


-- Methods - Functions

-- Events

function map:on_started()



end

function phone_interaction:on_interaction()

      phone_manager:talk(map)

end

for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end