-- Variables
local map = ...
local game = map:get_game()
local is_small_boss_active = false
local is_boss_active = false
local boss_key_enemies_index = 0
local is_boss_message_2_displayed = false
local is_boss_message_3_displayed = false

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")
local door_manager = require("scripts/maps/door_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local light_manager = require("scripts/maps/light_manager")
local separator_manager = require("scripts/maps/separator_manager")
local switch_manager = require("scripts/maps/switch_manager")
local treasure_manager = require("scripts/maps/treasure_manager")
local block_manager = require("scripts/maps/block_manager")

-- Map events
map:register_event("on_started", function()

  -- Chests
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_compass",  "dungeon_2_compass")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_small_key_4",  "dungeon_2_small_key_4")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_power_bracelet",  "dungeon_2_power_bracelet")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_boss_key",  "dungeon_2_boss_key")
  treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_3_", "chest_compass")
  treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_17_", "chest_power_bracelet")
  -- Blocks
  map:init_block_group_1()
  -- Doors
  map:set_doors_open("door_group_4_", true)
  map:set_doors_open("door_group_small_boss", true)
  map:set_doors_open("door_group_boss", true)
  door_manager:open_when_torches_lit(map, "torch_group_1_", "door_group_1_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_8_",  "door_group_4_")
  -- Ennemies
  enemy_manager:create_teletransporter_if_small_boss_dead(map, false)
  enemy_manager:set_weak_boo_buddies_on_torch_lit(map, "torch_group_6_", "enemy_group_17_")
  -- Light
  light_manager:init(map)
  -- Music
  game:play_dungeon_music()
  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_small_key_1")
  treasure_manager:disappear_pickable(map, "pickable_small_key_2")
  treasure_manager:disappear_pickable(map, "heart_container")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_2_", "pickable_small_key_1")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_5_", "pickable_small_key_2")
  treasure_manager:appear_heart_container_if_boss_dead(map)
  -- Switchs
  switch_manager:activate_switch_if_savegame_exist(map, "switch_1",  "dungeon_2_small_key_4")
  -- Walls
  if game:get_value("dungeon_2_wall_1") then
    for entity in map:get_entities("wall_1_") do
      entity:remove()
    end
  end
  if game:get_value("dungeon_2_wall_2") then
    for entity in map:get_entities("wall_2_") do
      entity:remove()
    end
  end
  -- Separators
  separator_manager:init(map)

end)


function map:on_obtaining_treasure(item, variant, savegame_variable)

  if savegame_variable == "dungeon_2_big_treasure" then
    treasure_manager:get_instrument(map)
    game:set_step_done("dungeon_2_completed")
  end

end

function map:init_block_group_1()

  if not game:get_value("dungeon_2_wall_1") then
    block_manager:init_block_riddle(map, "auto_block_group_1", function()
      door_manager:open_hidden_staircase(map, "wall_1", "dungeon_2_wall_1") 
    end)
  end

end

-- Enemies events
enemy_group_15_1:register_event("on_dead", function()

  if boss_key_enemies_index == 0 then
    boss_key_enemies_index = 1
  end

end)

enemy_group_15_2:register_event("on_dead", function()

  if boss_key_enemies_index == 1 then
    boss_key_enemies_index = 2
  end

end)

enemy_group_15_3:register_event("on_dead", function()

  if boss_key_enemies_index == 2 then
    treasure_manager:appear_chest(map, "chest_boss_key", true)
  end

end)

enemy_group_16_1:register_event("on_dead", function()

  local remaining = map:get_entities_count("enemy_group_16_")
  if remaining == 0 and not game:get_value("dungeon_2_wall_2") then
    door_manager:open_hidden_staircase(map, "wall_2", "dungeon_2_wall_2") 
  end

end)

enemy_group_16_2:register_event("on_dead", function()

  local remaining = map:get_entities_count("enemy_group_16_")
  if remaining == 0 and not game:get_value("dungeon_2_wall_2") then
    door_manager:open_hidden_staircase(map, "wall_2", "dungeon_2_wall_2") 
  end

end)

enemy_group_16_3:register_event("on_dead", function()

  local remaining = map:get_entities_count("enemy_group_16_")
  if remaining == 0 and not game:get_value("dungeon_2_wall_2") then
    door_manager:open_hidden_staircase(map, "wall_2", "dungeon_2_wall_2") 
  end

end)

-- Sensors events
sensor_1:register_event("on_activated", function()

  if is_small_boss_active == false then
    is_small_boss_active = true
    enemy_manager:launch_small_boss_if_not_dead(map)
  end

end)

sensor_2:register_event("on_activated", function()
    
  if is_small_boss_active == false then
    is_small_boss_active = true
    enemy_manager:launch_small_boss_if_not_dead(map)
  else
    map:close_doors("door_group_small_boss_2")
  end
  map:close_doors("door_group_wallturn")

end)

sensor_3:register_event("on_activated", function()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_8_", "door_group_4_")

end)

sensor_4:register_event("on_activated", function()

  door_manager:close_if_torches_unlit(map, "torch_group_1_", "door_group_1_")

end)

sensor_boss:register_event("on_activated", function()

  if is_boss_active == false then
    is_boss_active = true
    enemy_manager:launch_boss_if_not_dead(map)

    -- Display dialogs related to boss steps.
    function boss:on_step_started(step)
      if step == 2 then
        game:start_dialog("maps.dungeons.2.boss_message_1")
      elseif step == 3 and not is_boss_message_2_displayed then
        is_boss_message_2_displayed = true
        game:start_dialog("maps.dungeons.2.boss_message_2")
      elseif step == 4 and not is_boss_message_3_displayed then
        is_boss_message_3_displayed = true
        game:start_dialog("maps.dungeons.2.boss_message_3")
      end
    end
  end

end)

switch_1:register_event("on_activated", function()

  treasure_manager:appear_chest(map, "chest_small_key_4", true)

end)
