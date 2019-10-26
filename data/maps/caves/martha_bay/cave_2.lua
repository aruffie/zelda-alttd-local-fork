-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local separator_manager = require("scripts/maps/separator_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  -- Entities
  map:init_map_entities()
  
end)

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("18_cave")

end

-- Initializes entities based on player's progress
function map:init_map_entities()
 
  --Invisible things: only visible with the Lens
  for entity in map:get_entities("invisible_entity") do
    if game:get_value("get_lens") then
      entity:set_visible(true)
    else
      entity:set_visible(false)
    end
  end

end

--Invisible things: only visible with the Lens
function map:on_obtained_treasure(item, variant, treasure_savegame_variable)
  
  if item:get_name() == "magnifying_lens" and item:get_variant() == 14 then
    for entity in map:get_entities("invisible_entity") do
			entity:set_visible(false)
		end
  end
  
end

-- Separators
separator_manager:init(map)