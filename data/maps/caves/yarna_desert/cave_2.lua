-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local separator_manager = require("scripts/maps/separator_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events
map:register_event("on_started", function(map, destination)

  -- Entities
  map:init_map_entities()
  -- Music
  map:init_music()
  
end)

-- Initializes Entities based on player's progress
function map:init_map_entities()
  
  if angler_key then
  angler_key:set_enabled(false)
    if game:is_step_last("sandworm_killed") then
      angler_key:set_enabled(true)
    end
  end
  
end

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("18_cave")

end

-- Obtaining angler key
function map:on_obtaining_treasure(treasure_item, treasure_variant, treasure_savegame_variable)

  if treasure_item:get_name() == "angler_key" then
    game:set_step_done("dungeon_4_key_obtained")
  end

end

-- Doors events
function weak_door_1:on_opened()
  
  audio_manager:play_sound("misc/secret1")
  
end

-- Separators
separator_manager:init(map)