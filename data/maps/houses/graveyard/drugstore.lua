-- Variables
local map = ...
local game = map:get_game()

-- Map events
function map:on_started(destination)

  -- Music
  map:init_music()
  
end

-- Initialize the music of the map
function map:init_music()

  -- Todo add music drugsto

end

-- NPCs events
-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end
