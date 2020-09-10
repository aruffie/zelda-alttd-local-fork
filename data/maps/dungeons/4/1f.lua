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

  -- Doors
  map:set_doors_open("door_group_1_", true)
  map:set_doors_open("door_group_2_", true)
  map:set_doors_open("door_group_3_", true)
  map:set_doors_open("door_group_6_", true)
  map:set_doors_open("door_group_small_boss_", true)
  door_manager:open_when_enemies_dead(map,  "enemy_group_4_",  "door_group_1_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_2_",  "door_group_2_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_1_",  "door_group_3_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_23_",  "door_group_6_")
  door_manager:open_when_switch_activated(map, "switch_1", "door_group_4_")
  -- Enemies
  enemy_manager:create_teletransporter_if_small_boss_dead(map, false)
  -- Music
  game:play_dungeon_music()
  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_small_key_1")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_8_", "pickable_small_key_1")
  treasure_manager:appear_heart_container_if_boss_dead(map)
  -- Separators
  separator_manager:init(map)
  
end)

function map:on_obtaining_treasure(item, variant, savegame_variable)

  if savegame_variable == "dungeon_4_big_treasure" then
    treasure_manager:get_instrument(map)
  end

end

-- Sensors events
function sensor_1:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_4_", "door_group_1_")

end

function sensor_2:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_2_", "door_group_2_")

end

function sensor_3:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_2_", "door_group_2_")

end

function sensor_4:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_4_", "door_group_1_")

end

function sensor_5:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_4_", "door_group_1_")

end

function sensor_6:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_4_", "door_group_1_")

end

function sensor_7:on_activated()

  door_manager:close_if_enemies_not_dead(map,  "enemy_group_1_",  "door_group_3_")

end

function sensor_8:on_activated()

  if is_small_boss_active == false then
    is_small_boss_active = true
    enemy_manager:launch_small_boss_if_not_dead(map)
  end

end

function sensor_9:on_activated()

  if is_boss_active == false then
    is_boss_active = true
    enemy_manager:launch_boss_if_not_dead(map)
  end

end

function sensor_10:on_activated()

  door_manager:close_if_enemies_not_dead(map,  "enemy_group_23_",  "door_group_6_")

end

function sensor_11:on_activated()

  sensor_10:on_activated()

end