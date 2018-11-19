-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local separator_manager = require("scripts/maps/separator_manager")
local treasure_manager = require("scripts/maps/treasure_manager")
local door_manager = require("scripts/maps/door_manager")

-- Map events
function map:on_started(destination)

  -- Music
  map:init_music()
  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_golden_leaf_4")
  
end


-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("32_kanalet_castle")

end

-- Treasures events
treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_2_", "pickable_golden_leaf_4")

-- Separators
separator_manager:manage_map(map)