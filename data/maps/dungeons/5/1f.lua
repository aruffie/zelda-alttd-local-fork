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
local switch_manager = require("scripts/maps/switch_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local separator_manager = require("scripts/maps/separator_manager")
local owl_manager = require("scripts/maps/owl_manager")

function map:on_started()

 local hero = map:get_hero()
  -- Init music
  game:play_dungeon_music()
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_beak_of_stone",  "dungeon_5_beak_of_stone")



end

function map:on_opening_transition_finished(destination)

  treasure_manager:disappear_pickable(map, "pickable_small_key_1")
  map:set_doors_open("door_group_6", true)
  if destination == dungeon_5_1_B then
    game:start_dialog("maps.dungeons.5.welcome")
  end

end


-- Enemies


-- Treasures
treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_10", "chest_beak_of_stone")
treasure_manager:appear_pickable_when_blocks_moved(map, "block_group_1", "pickable_small_key_1") 


-- Doors

door_manager:open_when_enemies_dead(map,  "enemy_group_5",  "door_group_1")
door_manager:open_when_enemies_dead(map,  "enemy_group_4",  "door_group_1")
door_manager:open_when_enemies_dead(map,  "enemy_group_9",  "door_group_2")
door_manager:open_when_enemies_dead(map,  "enemy_group_11",  "door_group_3")
door_manager:open_when_enemies_dead(map,  "enemy_group_20",  "door_group_5")
door_manager:open_when_enemies_dead(map,  "enemy_group_22",  "door_group_5")
door_manager:open_when_enemies_dead(map,  "enemy_group_24",  "door_group_6")
-- Small boss Step 1
door_manager:open_when_enemies_dead(map,  "enemy_group_12",  "door_group_3")

-- Small boss Step 2
door_manager:open_when_enemies_dead(map,  "enemy_group_18",  "door_group_4")

-- Small boss Step 3
door_manager:open_when_enemies_dead(map,  "enemy_group_23",  "door_group_5")

-- Blocks


-- Sensors events

function sensor_1:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_4", "door_group_1")

end

function sensor_2:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_5", "door_group_1")

end

function sensor_3:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_12", "door_group_3")

end

function sensor_4:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_18", "door_group_4")

end

function sensor_5:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_23", "door_group_5")

end

function sensor_6:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_22", "door_group_5")

end

function sensor_7:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_24", "door_group_6")

end

-- Switchs events

function switch_1:on_activated()

  map:open_doors("door_group_4")
  sol.audio.play_sound("secret_1")

end


-- Chests events

function chest_hookshot_fail:on_opened()

    game:start_dialog("maps.dungeons.5.chest_hookshot_fail", function()
      hero:unfreeze()
    end)

end

-- Separator events

auto_separator_15:register_event("on_activating", function(separator, direction4)
  switch_1:set_activated(false)
  block_group_2_1:reset()
  local x, y = hero:get_position()
  if direction4 == 0 then
    map:close_doors("door_group_4")
  end
end)

auto_separator_16:register_event("on_activating", function(separator, direction4)
  switch_1:set_activated(false)
  block_group_2_1:reset()
  local x, y = hero:get_position()
  if direction4 == 1 then
    map:close_doors("door_group_4")
  end
end)

auto_separator_21:register_event("on_activating", function(separator, direction4)
  switch_1:set_activated(false)
  block_group_2_1:reset()
  local x, y = hero:get_position()
  if direction4 == 3 then
    map:close_doors("door_group_4")
  end
end)



separator_manager:manage_map(map)
owl_manager:manage_map(map)

