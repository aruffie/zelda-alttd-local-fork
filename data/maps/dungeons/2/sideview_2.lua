
-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local separator_manager = require("scripts/maps/separator_manager")
local map_tools = require("scripts/maps/map_tools")

-- Map events
function map:on_started()

  -- Music
  map:init_music()
  -- Sideview
  map:set_sideview(true)
  -- Separators
  separator_manager:init(map)

end

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("20_sidescrolling")

  -- Initialize parallax strength for further entities.
  for entity in map:get_entities("thin_column") do
    map_tools.start_parallax_scrolling(entity, entity:get_property("parallax_scrolling"))
  end
end