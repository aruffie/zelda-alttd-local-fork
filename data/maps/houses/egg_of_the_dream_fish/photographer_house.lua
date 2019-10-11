-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  
end)

-- Initialize the music of the map
function map:init_music()

  -- Todo add music photograph

end