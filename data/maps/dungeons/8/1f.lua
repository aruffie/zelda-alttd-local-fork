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

-- FSA settings
map.fsa_lava = true

-----------------------
-- Map events
-----------------------
function map:on_started()
-- TODO check 1776 1573 chest treasure
-- TODO dark rooms

  -- Heart
  treasure_manager:appear_heart_container_if_boss_dead(map)

  -- Doors
  door_manager:open_weak_wall_if_savegame_exist(map, "weak_wall_A", "dungeon_8_weak_wall_A")
  door_manager:open_weak_wall_if_savegame_exist(map, "weak_wall_B", "dungeon_8_weak_wall_B")
  door_manager:open_weak_wall_if_savegame_exist(map, "weak_wall_C", "dungeon_8_weak_wall_C")
  door_manager:open_weak_wall_if_savegame_exist(map, "weak_wall_D", "dungeon_8_weak_wall_D")
  door_manager:open_weak_wall_if_savegame_exist(map, "weak_wall_E", "dungeon_8_weak_wall_E")
  door_manager:open_weak_wall_if_savegame_exist(map, "weak_wall_F", "dungeon_8_weak_wall_F")
  door_manager:open_when_enemies_dead(map,  "enemy_group_1_",  "door_group_1")
  door_manager:open_when_enemies_dead(map,  "enemy_group_1_",  "door_group_11")
  door_manager:open_when_enemies_dead(map,  "enemy_group_2_",  "door_group_17")
  door_manager:open_when_enemies_dead(map,  "hinox_master",  "door_group_3")
  door_manager:open_when_enemies_dead(map,  "rolling_bones",  "door_group_4")
  door_manager:open_when_enemies_dead(map,  "rolling_bones",  "door_group_5")
  door_manager:open_when_enemies_dead(map,  "rolling_bones",  "door_group_6")
  door_manager:open_when_enemies_dead(map,  "enemy_group_8_",  "door_group_7")
  door_manager:open_when_enemies_dead(map,  "smasher",  "door_group_7")
  door_manager:open_when_enemies_dead(map,  "smasher",  "door_group_8")
  door_manager:open_when_enemies_dead(map,  "smasher",  "door_group_12")
  door_manager:open_when_enemies_dead(map,  "enemy_group_19",  "door_group_18")
  door_manager:open_if_small_boss_dead(map)

  -- Pickables
  treasure_manager:disappear_pickable(map, "heart_container")
  treasure_manager:disappear_pickable(map, "pickable_small_key_1")
  treasure_manager:disappear_pickable(map, "pickable_small_key_2")
  treasure_manager:disappear_pickable(map, "pickable_small_key_3")
  treasure_manager:disappear_pickable(map, "pickable_small_key_4")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_3", "pickable_small_key_1")
  treasure_manager:appear_pickable_when_holes_filled(map, "vacuum_cleaner_2", "pickable_small_key_2")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_13", "pickable_small_key_3")
  treasure_manager:appear_pickable_when_hit_by_arrow(map, "statue_eye_1", "pickable_small_key_4")

  -- Chests
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_rupee_1", "dungeon_8_rupee_1")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_boss_key", "dungeon_8_boss_key")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_small_key_7", "dungeon_8_small_key_7")
  treasure_manager:appear_chest_when_holes_filled(map, "vacuum_cleaner_1", "chest_rupee_1")
  treasure_manager:appear_chest_when_holes_filled(map, "vacuum_cleaner_3", "chest_boss_key")
  treasure_manager:appear_chest_when_torches_lit(map, "torch_1_", "chest_small_key_7")

  -- Music
  game:play_dungeon_music()

  -- Separators
  separator_manager:init(map)

  -- Ennemies
  enemy_manager:create_teletransporter_if_small_boss_dead(map, false)

  -- Make area invisible.
  area_pit:set_visible(false)
end


function map:on_obtaining_treasure(item, variant, savegame_variable)

  if savegame_variable == "dungeon_8_big_treasure" then
    treasure_manager:get_instrument(map)
  end

end

-----------------------
-- Doors events
-----------------------
map:set_doors_open("door_group_17", true)

wallturn:add_collision_test("touching", function(wallturn, hero)
  door_group_13_1:set_open()
end)

weak_wall_A_1:register_event("on_opened", function()
  door_manager:destroy_wall(map, "weak_wall_A")
end)

weak_wall_B_1:register_event("on_opened", function()
  door_manager:destroy_wall(map, "weak_wall_B")
end)

weak_wall_C_1:register_event("on_opened", function()
  door_manager:destroy_wall(map, "weak_wall_C")
end)

weak_wall_D_1:register_event("on_opened", function()
  door_manager:destroy_wall(map, "weak_wall_D")
end)

weak_wall_E_1:register_event("on_opened", function()
  door_manager:destroy_wall(map, "weak_wall_E")
end)

weak_wall_F_1:register_event("on_opened", function()
  door_manager:destroy_wall(map, "weak_wall_F")
end)

weak_wall_G_1:register_event("on_opened", function()
  door_manager:destroy_wall(map, "weak_wall_G")
end)

sensor_1:register_event("on_activated", function()
  map:close_doors("door_group_4_")
  map:close_doors("door_group_5_")
  map:close_doors("door_group_6_")
end)

sensor_2:register_event("on_activated", function()
  map:close_doors("door_group_7_")
  map:close_doors("door_group_8_")
  map:close_doors("door_group_12_")
end)

sensor_3:register_event("on_activated", function()
  map:close_doors("door_group_9_")
  map:close_doors("door_group_10_")
end)

sensor_4:register_event("on_activated", function()
  map:close_doors("door_group_13_")
  map:close_doors("door_group_14_")
end)

sensor_5:register_event("on_activated", function()
  if map:has_entities("enemy_group_2_") then
    map:close_doors("door_group_17_")
  end
end)

sensor_6:register_event("on_activated", function()
  map:close_doors("door_group_15_")
  map:close_doors("door_group_22_")
end)

sensor_7:register_event("on_activated", function()
  
  if is_boss_active == false then
    is_boss_active = true
    map:close_doors("door_group_boss_3")
    map:close_doors("door_group_boss_6")
    enemy_manager:launch_boss_if_not_dead(map)

    boss:register_event("on_dying", function(boss)
      game:start_dialog("maps.dungeons.8.boss_dying")
    end)
  end
end)

-- Deactivate the small boss if going out the room while active.
separator_small_boss:register_event("on_activating", function(separator_small_boss, direction4)

  if direction4 == 1 and enemy_small_boss then
    enemy_small_boss:set_enabled(false)
    game:play_dungeon_music()
  end
end)

-- Launch the small boss if needed.
separator_small_boss:register_event("on_activated", function(separator_small_boss, direction4)

  if direction4 == 3 then
    if not enemy_small_boss then
      enemy_manager:launch_small_boss_if_not_dead(map)

      -- Teleport the hero to the dungeon entrance if ejected.
      function enemy_small_boss:on_hero_ejected()
        local _, destination_y = dungeon_8_1_B:get_position()
        hero:teleport("dungeons/8/1f", "dungeon_8_1_B", "fade")
        hero:fall_from_ceiling(destination_y % 240)
        enemy_small_boss:set_enabled(false)
        game:play_dungeon_music()
      end
    else
      enemy_small_boss:set_position(placeholder_small_boss:get_position())
      enemy_small_boss:set_life(8)
      enemy_small_boss:set_enabled(true)
      audio_manager:play_music("21_mini_boss_battle")
    end
  end
end)
