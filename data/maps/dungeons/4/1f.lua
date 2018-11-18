-- Lua script of map dungeons/4/1f.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local separator = ...
local game = map:get_game()
local is_small_boss_active = false
local is_boss_active = false

 local door_manager = require("scripts/maps/door_manager")
 local treasure_manager = require("scripts/maps/treasure_manager")
 local enemy_manager = require("scripts/maps/enemy_manager")
 local separator_manager = require("scripts/maps/separator_manager")
 local owl_manager = require("scripts/maps/owl_manager")

function map:on_started()

 local hero = map:get_hero()
  -- Init music
  game:play_dungeon_music()
  treasure_manager:disappear_pickable(map, "pickable_small_key_1")
  enemy_manager:create_teletransporter_if_small_boss_dead(map, false)
  treasure_manager:appear_heart_container_if_boss_dead(map)
end

function map:on_opening_transition_finished(destination)

  map:set_doors_open("door_group_1_", true)
  map:set_doors_open("door_group_2_", true)
  map:set_doors_open("door_group_3_", true)
  map:set_doors_open("door_group_6_", true)
  map:set_doors_open("door_group_small_boss_", true)
  if destination == dungeon_4_1_B then
    game:start_dialog("maps.dungeons.4.welcome")
  end

end

-- Treasures

treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_8_", "pickable_small_key_1")

-- Doors

door_manager:open_when_enemies_dead(map,  "enemy_group_4_",  "door_group_1_")
door_manager:open_when_enemies_dead(map,  "enemy_group_2_",  "door_group_2_")
door_manager:open_when_enemies_dead(map,  "enemy_group_1_",  "door_group_3_")
door_manager:open_when_enemies_dead(map,  "enemy_group_23_",  "door_group_6_")
door_manager:open_when_switch_activated(map, "switch_1", "door_group_4_")

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

-- Separator events

function auto_separator_5:on_activating(direction4)
  for block in map:get_entities("block_group_1_") do
    block:reset()
  end
end

function auto_separator_6:on_activating(direction4)
  auto_separator_5:on_activating(direction4)
end

function auto_separator_12:on_activating(direction4)
  auto_separator_5:on_activating(direction4)
end

function auto_separator_13:on_activating(direction4)
  auto_separator_5:on_activating(direction4)
end

separator_manager:manage_map(map)
owl_manager:manage_map(map)

