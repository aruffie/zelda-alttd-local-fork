-- Lua script of map dungeons/7/2f.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

-----------------------
-- Variables
-----------------------
local map = ...
local game = map:get_game()

-----------------------
-- Include scripts
-----------------------
local audio_manager = require("scripts/audio_manager")
local door_manager = require("scripts/maps/door_manager")
local treasure_manager = require("scripts/maps/treasure_manager")
local switch_manager = require("scripts/maps/switch_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local separator_manager = require("scripts/maps/separator_manager")
local owl_manager = require("scripts/maps/owl_manager")
require("scripts/multi_events")

-----------------------
-- Map events
-----------------------
function map:on_started()

  -- Owl
  owl_manager:init(map)

  -- Chests
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_map", "dungeon_7_map")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_compass", "dungeon_7_compass")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_bomb_1", "dungeon_7_bomb_1")

  -- Doors
  map:set_doors_open("door_group_1_", false)
  map:set_doors_open("door_group_2_", true)

  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_small_key_2")
end

-- TODO Move blocks "block_1_" when handle is pulled

-----------------------
-- Doors events
-----------------------
door_manager:open_when_flying_tiles_dead(map,  "enemy_group_10_",  "door_group_2_")

weak_wall_A_1:register_event("on_opened", function()
  weak_wall_closed_A_1:remove();
  weak_wall_closed_A_2:remove();
  audio_manager:play_sound("misc/secret1")
end)

weak_wall_B_1:register_event("on_opened", function()
  weak_wall_closed_B_1:remove();
  weak_wall_closed_B_2:remove();
  audio_manager:play_sound("misc/secret1")
end)

-----------------------
-- Treasures events
-----------------------
treasure_manager:appear_pickable_when_enemies_dead(map, "hinox_master", "pickable_small_key_2")

-----------------------
-- Sensors events
-----------------------
sensor_1:register_event("on_activated", function()
  map:open_doors("door_group_1_")
end)

sensor_2:register_event("on_activated", function()
  map:close_doors("door_group_1_")
  map:close_doors("door_group_2_")
end)

-----------------------
-- Enemies events
-----------------------
enemy_manager:execute_when_vegas_dead(map, "enemy_group_3_")
enemy_manager:execute_when_vegas_dead(map, "enemy_group_7_")

-----------------------
-- Treasures events
-----------------------
-- TODO appear chest "chest_map" when horse heads are correctly thrown
treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_3_", "chest_compass")
treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_7_", "chest_bomb_1")

-----------------------
-- Separators
-----------------------
separator_manager:init(map)