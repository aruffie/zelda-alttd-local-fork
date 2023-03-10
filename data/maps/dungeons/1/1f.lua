-- Variables
local map = ...
local game = map:get_game()
local is_small_boss_active = false
local is_boss_active = false

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")
local door_manager = require("scripts/maps/door_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local separator_manager = require("scripts/maps/separator_manager")
local switch_manager = require("scripts/maps/switch_manager")
local treasure_manager = require("scripts/maps/treasure_manager")

-- Map events

map:register_event("on_started", function()
    
  -- Chests
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_small_key_2",  "dungeon_1_small_key_2")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_map",  "dungeon_1_map")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_beak_of_stone",  "dungeon_1_beak_of_stone")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_rupee_1",  "dungeon_1_rupee_1")
  treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_12_", "chest_rupee_1")
  treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_13_", "chest_beak_of_stone")
  treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_4_", "chest_map")
  -- Doors
  map:set_doors_open("door_group_2_", true)
  map:set_doors_open("door_group_1_", true)
  map:set_doors_open("door_group_small_boss", true)
  map:set_doors_open("door_group_boss", true)
  door_manager:open_weak_wall_if_savegame_exist(map, "weak_wall_group_1_", "dungeon_1_weak_wall_group_1")
  door_manager:open_when_enemies_dead(map,  "enemy_group_6_",  "door_group_1")
  door_manager:open_when_enemies_dead(map,  "enemy_group_3_",  "door_group_5")
  door_manager:open_when_block_moved(map, "auto_block_1", "door_group_2")
  door_manager:open_if_small_boss_dead(map)
  -- Enemies
  enemy_manager:create_teletransporter_if_small_boss_dead(map, false)
  enemy_manager:execute_when_vegas_dead(map, "enemy_group_13_")
  if not game:get_value("dungeon_1_wall_1") then
    enemy_manager:on_enemies_dead(map, "enemy_group_15_", function()
        door_manager:open_hidden_staircase(map, "wall_1", "dungeon_1_wall_1") 
      end)
  end
  -- Music
  game:play_dungeon_music()
  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_small_key_1")
  treasure_manager:disappear_pickable(map, "heart_container")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_7_", "pickable_small_key_1")
  treasure_manager:appear_heart_container_if_boss_dead(map)
  -- Switchs
  switch_manager:activate_switch_if_savegame_exist(map, "switch_1",  "dungeon_1_small_key_2")
  -- Walls
  if game:get_value("dungeon_1_wall_1") then
    for entity in map:get_entities("wall_1_") do
      entity:remove()
    end
  end
  -- Separators
  separator_manager:init(map)
  
end)

map:register_event("on_opening_transition_finished", function()

  map:set_doors_open("door_group_5_", true)
  if destination == dungeon_1_1_B then
    map:set_doors_open("door_group_2_", false)
  end

end)


function map:on_obtaining_treasure(item, variant, savegame_variable)

  if savegame_variable == "dungeon_1_big_treasure" then
    treasure_manager:get_instrument(map)
    game:set_step_done("dungeon_1_completed")
  end

end

-- Doors events
weak_wall_group_1:register_event("on_opened", function()

  door_manager:destroy_wall(map, "weak_wall_group_1_")

end)

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

end)

sensor_8:register_event("on_activated", function()

  door_manager:open_if_block_moved(map,  "auto_block_1" , "door_group_2_")

end)

sensor_15:register_event("on_activated", function()

  map:set_doors_open("door_group_2", false)

end)

-- Switchs events
switch_1:register_event("on_activated", function()

  treasure_manager:appear_chest(map, "chest_small_key_2", true)

end)

-- Enemies events
enemy_manager:on_enemies_dead(map, "enemy_group_3_", function()
    
  enemy_group_torch_1:set_shooting(false)
  enemy_group_torch_2:set_shooting(false)
  
end)