-- Variables
local map = ...
local game = map:get_game()
local is_small_boss_active = false
local is_boss_active = false

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

  -- Music
  game:play_dungeon_music()
  -- Owl
  owl_manager:init(map)
  -- Chests
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_small_key_2",  "dungeon_1_small_key_2")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_map",  "dungeon_1_map")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_beak_of_stone",  "dungeon_1_beak_of_stone")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_rupee_1",  "dungeon_1_rupee_1")
  -- Doors
  map:set_doors_open("door_group_2_", true)
  map:set_doors_open("door_group_1_", true)
  map:set_doors_open("door_group_small_boss", true)
  -- Ennemies
  enemy_manager:create_teletransporter_if_small_boss_dead(map, false)
  -- Heart
  treasure_manager:appear_heart_container_if_boss_dead(map)
  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_small_key_1")
  treasure_manager:disappear_pickable(map, "heart_container")
  -- Switchs
  switch_manager:activate_switch_if_savegame_exist(map, "switch_1",  "dungeon_1_small_key_2")

end

function map:on_opening_transition_finished(destination)

  map:set_doors_open("door_group_5_", true)
  if destination == dungeon_1_1_B then
    map:set_doors_open("door_group_2_", false)
    game:start_dialog("maps.dungeons.1.welcome")
  end

end

function map:on_obtaining_treasure(item, variant, savegame_variable)

  if savegame_variable == "dungeon_1_big_treasure" then
    treasure_manager:get_instrument(map)
  end

end

-- Blocks events
door_manager:open_when_block_moved(map, "auto_block_1", "door_group_2")

-- Doors events
door_manager:open_when_enemies_dead(map,  "enemy_group_6_",  "door_group_1")
door_manager:open_when_enemies_dead(map,  "enemy_group_3_",  "door_group_5")
door_manager:open_if_small_boss_dead(map)
door_manager:open_if_boss_dead(map)

door_small_key_3_1:register_event("on_opened", function()
    
  audio_manager:play_sound("others/dungeon_door_open")
      
end)

door_small_key_2_1:register_event("on_opened", function()
    
  audio_manager:play_sound("others/dungeon_door_open")
      
end)


weak_wall_A_1:register_event("on_opened", function()

  weak_wall_closed_A_1:remove();
  weak_wall_closed_A_2:remove();
  audio_manager:play_sound("others/secret1")

end)

-- Enemies events
enemy_manager:execute_when_vegas_dead(map, "enemy_group_13")

-- Sensors events
sensor_1:register_event("on_activated", function()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_6_", "door_group_1_")

end)

sensor_2:register_event("on_activated", function()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_6_", "door_group_1_")

end)

sensor_3:register_event("on_activated", function()

  if is_small_boss_active == false then
    is_small_boss_active = true
    enemy_manager:launch_small_boss_if_not_dead(map)
  end

end)

sensor_4:register_event("on_activated", function()

  if is_boss_active == false then
    is_boss_active = true
    enemy_manager:launch_boss_if_not_dead(map)
  end

end)

sensor_5:register_event("on_activated", function()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_3_", "door_group_5_")

end)

sensor_6:register_event("on_activated", function()

  map:set_doors_open("door_group_6", true)

end)

sensor_7:register_event("on_activated", function()


  map:close_doors("door_group_6_")
  audio_manager:play_sound("others/dungeon_door_slam")

end)

sensor_8:register_event("on_activated", function()

  door_manager:open_if_block_moved(map,  "auto_block_1" , "door_group_2_")

end)

-- Separators events
auto_separator_17:register_event("on_activating", function(separator, direction4)
    
  map:set_doors_open("door_group_2", false)
  
end)

-- Switchs events
switch_1:register_event("on_activated", function()

  treasure_manager:appear_chest(map, "chest_small_key_2", true)

end)

-- Treasures events
treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_7_", "pickable_small_key_1")
treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_12_", "chest_rupee_1")
treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_13_", "chest_beak_of_stone")
treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_4_", "chest_map")

-- Separators
separator_manager:init(map)