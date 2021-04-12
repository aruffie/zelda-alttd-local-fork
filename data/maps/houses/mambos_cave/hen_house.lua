-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  -- NPC
  if game:get_value("dungeon_7_big_treasure") then
    -- TODO Flying Cuccos Keeper.
  end
end)

-- Initialize the music of the map
function map:init_music()

  -- Todo Add music cucco
end

-- Cucco's Keeper dialog.
function cuccos_keeper:on_interaction()

  if game:get_value("dungeon_7_big_treasure") then
    game:start_dialog("maps.houses.mambos_cave.hen_house.cuccos_keeper_dungeon_7_done")
  elseif game:get_value("chicken_joined") then
    game:start_dialog("maps.houses.mambos_cave.hen_house.cuccos_keeper_chicken")
  else
    game:start_dialog("maps.houses.mambos_cave.hen_house.cuccos_keeper_no_chicken")
  end
end