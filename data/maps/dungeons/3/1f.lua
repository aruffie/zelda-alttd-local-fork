-- Variables
local map = ...
local game = map:get_game()
local is_small_boss_active = false

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")
local door_manager = require("scripts/maps/door_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local separator_manager = require("scripts/maps/separator_manager")
local switch_manager = require("scripts/maps/switch_manager")
local treasure_manager = require("scripts/maps/treasure_manager")

-- Map events
function map:on_started()

  -- Chests
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_small_key_1",  "dungeon_3_small_key_1")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_rupee_1",  "dungeon_3_rupee_1")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_rupee_2",  "dungeon_3_rupee_2")
  treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_2_", "chest_small_key_1")
  treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_5_", "chest_rupee_1")
  treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_15_", "chest_rupee_2")
  -- Doors
  map:set_doors_open("door_group_1", true)
  map:set_doors_open("door_group_2", true)
  map:set_doors_open("door_group_3_", true)
  map:set_doors_open("door_group_4_", true)
  map:set_doors_open("door_group_5_", true)
  map:set_doors_open("door_group_6_", true)
  map:set_doors_open("door_group_small_boss", true)
  door_manager:open_when_pot_break(map, "door_group_1_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_3_",  "door_group_2_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_12_",  "door_group_3_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_9_",  "door_group_4_")
  door_manager:open_weak_wall_if_savegame_exist(map, "weak_wall_group_1_", "dungeon_3_weak_wall_group_1")
  door_manager:open_weak_wall_if_savegame_exist(map, "weak_wall_group_2_", "dungeon_3_weak_wall_group_2")
  door_manager:open_weak_wall_if_savegame_exist(map, "weak_wall_group_3_", "dungeon_3_weak_wall_group_3")
  -- Enemies
  enemy_manager:create_teletransporter_if_small_boss_dead(map, false)
  -- Music
  game:play_dungeon_music()
  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_small_key_4")
  treasure_manager:disappear_pickable(map, "pickable_small_key_5")
  treasure_manager:disappear_pickable(map, "pickable_small_key_6")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_7_", "pickable_small_key_4")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_17_", "pickable_small_key_5")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_16_", "pickable_small_key_6")
  treasure_manager:appear_heart_container_if_boss_dead(map)
  -- Separators
  separator_manager:init(map)

end

function map:on_opening_transition_finished(destination)       

  if destination == dungeon_3_1_B then
      map:close_doors("door_group_1_")
  end
  
end

-- Doors events
weak_wall_group_1:register_event("on_opened", function()
    
  door_manager:destroy_wall(map, "weak_wall_group_1_")
  
end)

weak_wall_group_2_1:register_event("on_opened", function()
    
  door_manager:destroy_wall(map, "weak_wall_group_2_")
  
end)

weak_wall_group_2_2:register_event("on_opened", function()
    
  door_manager:destroy_wall(map, "weak_wall_group_2_")
  
end)

weak_wall_group_3_1:register_event("on_opened", function()
    
  door_manager:destroy_wall(map, "weak_wall_group_3_")
  
end)

weak_wall_group_3_2:register_event("on_opened", function()
    
  door_manager:destroy_wall(map, "weak_wall_group_3_")
  
end)

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

function sensor_6:on_activated()

  map:close_doors("door_group_5_")

end

function sensor_7:on_activated()

  map:close_doors("door_group_6_")

end

function sensor_9:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_9_", "door_group_4_")

end

function sensor_10:on_activated()

  map:set_doors_open("door_group_4_", true)

end

function sensor_11:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_9_", "door_group_4_")

end

function sensor_12:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_9_", "door_group_4_")

end

sensor_8:register_event("on_activated", function()

  if is_small_boss_active == false then
    is_small_boss_active = true
    enemy_manager:launch_small_boss_if_not_dead(map)
  end

end)

--[[
-- Separators events
separator_1:register_event("on_activating", function(separator, direction4)
    
  if direction4 == 3 then
    is_small_boss_active = false
    map:set_doors_open("door_group_4", true)
    map:set_doors_open("door_group_small_boss", true)
    if enemy_small_boss ~= nil then
      enemy_small_boss:remove()
    end
    game:play_dungeon_music()
  elseif direction4 == 1 then
    if is_small_boss_active == false then
      is_small_boss_active = true
      enemy_manager:launch_small_boss_if_not_dead(map)
    end
  end
  
end)
--]]