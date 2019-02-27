-- Lua script of map dungeons/7/3f.
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
local function map:fill_empty_rooms()

  -- Get pillar states
  local are_pillars_broken = true
  for i = 1, 4 do
    if not game:get_value("dungeon_7_pillar_" .. i) then
      are_pillars_broken = false
      break
    end
  end

  -- Copy the correct region
  local reference_entity = are_pillars_broken and "door_group_boss_1" or "big_chasm"
  local entities_shift = {x = are_pillars_broken and -340 or 340, y = 720}

  for entity in self:get_entities_in_region(reference_entity) do
    local entity_position = entity.get_position()
    entity.set_position(entity_position.x - entities_shift.x, entity_position.y - entities_shift.y)
  end
end

function map:on_started()

  -- Rooms
  self:fill_empty_rooms()

  -- Chests
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_boss_key", "dungeon_7_boss_key")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_drug_1", "dungeon_7_drug_1")

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

-----------------------
-- Doors events
-----------------------
door_manager:open_if_small_boss_dead(map)
door_manager:open_if_boss_dead(map)

-----------------------
-- Sensors events
-----------------------
sensor_1:register_event("on_activated", function()
  enemy_manager:launch_small_boss_if_not_dead(map)
end)

-----------------------
-- Treasures events
-----------------------
treasure_manager:appear_pickable_when_blocks_moved(map, "block_2_", "chest_boss_key")
-- TODO appear "chest_drug_1" when horse heads are correctly thrown

-----------------------
-- Separators
-----------------------
separator_manager:init(map)