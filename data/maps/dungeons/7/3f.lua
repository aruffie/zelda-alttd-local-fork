-- Lua script of map dungeons/7/4f.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local door_manager = require("scripts/maps/door_manager")
local treasure_manager = require("scripts/maps/treasure_manager")
local switch_manager = require("scripts/maps/switch_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local separator_manager = require("scripts/maps/separator_manager")
local owl_manager = require("scripts/maps/owl_manager")
require("scripts/multi_events")

-- Map events
function map:on_started()

  -- Chests
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_boss_key",  "dungeon_7_boss_key")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_drug",  "dungeon_7_drug")

  -- Doors
  map:set_doors_open("door_group_1_", true)

  -- Ennemies
  enemy_manager:create_teletransporter_if_small_boss_dead(map, false)
end

function map:on_obtaining_treasure(item, variant, savegame_variable)

  if savegame_variable == "dungeon_7_big_treasure" then
    treasure_manager:get_instrument(map)
  end
end

-- Doors events
door_manager:open_if_small_boss_dead(map)
door_manager:open_if_boss_dead(map)

-- Sensors events
sensor_1:register_event("on_activated", function()

  if game:get_value("dungeon_7_small_boss") == false then
    map:close_doors("door_group_1_")
    enemy_manager:launch_small_boss_if_not_dead(map)
  end
end)

-- Treasures events
-- TODO appear "chest_boss_key" when blocks are correctly placed
-- TODO appear "chest_drug" when horse heads are correctly thrown