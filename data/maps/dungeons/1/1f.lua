local map = ...
local separator = ...
local game = map:get_game()
local is_small_boss_active = false
local is_boss_active = false

local door_manager = require("scripts/maps/door_manager")
local treasure_manager = require("scripts/maps/treasure_manager")
local switch_manager = require("scripts/maps/switch_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local separator_manager = require("scripts/maps/separator_manager")
local owl_manager = require("scripts/maps/owl_manager")

function map:on_started()

 local hero = map:get_hero()
  -- Init music
  game:play_dungeon_music()
  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_small_key_1")
  treasure_manager:disappear_pickable(map, "heart_container")
  -- Chests
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_small_key_2",  "dungeon_1_small_key_2")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_map",  "dungeon_1_map")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_beak_of_stone",  "dungeon_1_beak_of_stone")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_rupee_1",  "dungeon_1_rupee_1")
  -- Switchs
  switch_manager:activate_switch_if_savegame_exist(map, "switch_1",  "dungeon_1_small_key_2")
  enemy_manager:create_teletransporter_if_small_boss_dead(map, false)
  -- Heart
  treasure_manager:appear_heart_container_if_boss_dead(map)
  -- Doors
  map:set_doors_open("door_group_2_", true)
  map:set_doors_open("door_group_1_", true)
  map:set_doors_open("door_group_small_boss", true)

end

function map:on_opening_transition_finished(destination)

  map:set_doors_open("door_group_5_", true)
  if destination == dungeon_1_1_B then
    map:set_doors_open("door_group_2_", false)
    game:start_dialog("maps.dungeons.1.welcome")
  end

end

-- Enemies
enemy_manager:execute_when_vegas_dead(map, "enemy_group_13")

-- Treasures
treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_7_", "pickable_small_key_1")
treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_12_", "chest_rupee_1")
treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_13_", "chest_beak_of_stone")
treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_4_", "chest_map")

-- Doors
door_manager:open_when_enemies_dead(map,  "enemy_group_6_",  "door_group_1")
door_manager:open_when_enemies_dead(map,  "enemy_group_3_",  "door_group_5")
door_manager:open_if_small_boss_dead(map)
door_manager:open_if_boss_dead(map)

-- Blocks
door_manager:open_when_block_moved(map, "auto_block_1", "door_group_2")

-- Sensors events
function sensor_1:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_6_", "door_group_1_")

end

function sensor_2:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_6_", "door_group_1_")

end

function sensor_3:on_activated()

  if is_small_boss_active == false then
    is_small_boss_active = true
    enemy_manager:launch_small_boss_if_not_dead(map)
  end

end

function sensor_4:on_activated()

  if is_boss_active == false then
    is_boss_active = true
    enemy_manager:launch_boss_if_not_dead(map)
  end

end

function sensor_5:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_3_", "door_group_5_")

end

function sensor_6:on_activated()

  map:set_doors_open("door_group_6", true)

end

function sensor_7:on_activated()


  map:close_doors("door_group_6_")

end

function sensor_8:on_activated()

  door_manager:open_if_block_moved(map,  "auto_block_1" , "door_group_2_")

end


-- Switchs events
function switch_1:on_activated()

  treasure_manager:appear_chest(map, "chest_small_key_2", true)

end

-- Treasures events
function map:on_obtaining_treasure(item, variant, savegame_variable)

    if savegame_variable == "dungeon_1_big_treasure" then
      treasure_manager:get_instrument(map)
    end

end

-- Doors events
function weak_wall_A_1:on_opened()

  weak_wall_closed_A_1:remove();
  weak_wall_closed_A_2:remove();
  sol.audio.play_sound("secret_1")

end

auto_separator_17:register_event("on_activating", function(separator, direction4)
    map:set_doors_open("door_group_2", false)
end)

separator_manager:manage_map(map)
owl_manager:manage_map(map)