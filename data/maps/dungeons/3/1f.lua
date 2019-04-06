-- Variables
local map = ...
local game = map:get_game()
local is_small_boss_active = false
local is_boss_active = false

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local door_manager = require("scripts/maps/door_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local owl_manager = require("scripts/maps/owl_manager")
local separator_manager = require("scripts/maps/separator_manager")
local switch_manager = require("scripts/maps/switch_manager")
local treasure_manager = require("scripts/maps/treasure_manager")
require("scripts/multi_events")

-- Map events
function map:on_started()

  -- Chests
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_small_key_1",  "dungeon_3_small_key_1")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_rupee_1",  "dungeon_3_rupee_1")
  treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_2_", "chest_small_key_1")
  treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_5_", "chest_rupee_1")
  -- Doors
  map:set_doors_open("door_group_2", true)
  map:set_doors_open("door_group_3_", true)
  door_manager:open_when_pot_break(map, "door_group_1_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_3_",  "door_group_2_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_12_",  "door_group_3_")
  -- Enemies
  enemy_manager:create_teletransporter_if_small_boss_dead(map, false)
  -- Heart
  treasure_manager:appear_heart_container_if_boss_dead(map)
  -- Music
  game:play_dungeon_music()
  -- Owls
  owl_manager:init(map)
  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_small_key_1")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_7_", "pickable_small_key_1")
  -- Separators
  separator_manager:init(map)

end

function map:on_opening_transition_finished(destination)       

    if destination == dungeon_3_1_B then
      game:start_dialog("maps.dungeons.3.welcome")
    end
    
end

function map:on_obtaining_treasure(item, variant, savegame_variable)

  if savegame_variable == "dungeon_3_big_treasure" then
    treasure_manager:get_instrument(map)
  end

end

-- Sensors events
function sensor_1:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_3_", "door_group_2_")

end

function sensor_2:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_3_", "door_group_2_")

end

function sensor_3:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_3_", "door_group_2_")

end

function sensor_4:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_12_", "door_group_3_")

end

function sensor_5:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_12_", "door_group_3_")

end