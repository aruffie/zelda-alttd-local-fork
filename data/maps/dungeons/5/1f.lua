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
  map:set_doors_open("door_group_6_", true)
  if destination == dungeon_5_1_B then
    game:start_dialog("maps.dungeons.5.welcome")
  end

end


-- Enemies

function map:init_skeletons()

  local skeleton_step = game:get_value("dungeon_5_skeleton_step")
  if skeleton_step == nil then
    skeleton_step = 1
  end
  for enemy in map:get_entities("skeleton_") do
    enemy:set_enabled(false)
  end
  local enemy = map:get_entity("skeleton_" .. skeleton_step)
  print("skeleton_" .. skeleton_step)
print(enemy)
  if enemy ~= nil then
    enemy:set_enabled(true)
  end

end

function skeleton_1:on_dead()
  game:set_value("dungeon_5_skeleton_step", 2)
  game:play_dungeon_music()
end

function skeleton_2:on_dead()
  game:set_value("dungeon_5_skeleton_step", 3)
  game:play_dungeon_music()
end

function skeleton_3:on_dead()
  game:set_value("dungeon_5_skeleton_step", 4)
  game:play_dungeon_music()
end

function skeleton_4:on_dead()
  game:set_value("dungeon_5_skeleton_step", 5)
  game:play_dungeon_music()
end


-- Treasures
treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_10_", "chest_beak_of_stone")
treasure_manager:appear_pickable_when_blocks_moved(map, "block_group_1_", "pickable_small_key_1") 


-- Doors

door_manager:open_when_enemies_dead(map,  "enemy_group_5_",  "door_group_1_")
door_manager:open_when_enemies_dead(map,  "enemy_group_4_",  "door_group_1_")
door_manager:open_when_enemies_dead(map,  "enemy_group_9_",  "door_group_2_")
door_manager:open_when_enemies_dead(map,  "enemy_group_11_",  "door_group_3_")
door_manager:open_when_enemies_dead(map,  "enemy_group_20_",  "door_group_5_")
door_manager:open_when_enemies_dead(map,  "enemy_group_22_",  "door_group_5_")
-- Small boss Step 1
door_manager:open_when_enemies_dead(map,  "skeleton_1",  "door_group_3_")

-- Small boss Step 2
door_manager:open_when_enemies_dead(map,  "skeleton_2",  "door_group_4_")

-- Small boss Step 3
door_manager:open_when_enemies_dead(map,  "skeleton_3",  "door_group_5_")

-- Small boss Step 4
door_manager:open_when_enemies_dead(map,  "skeleton_4",  "door_group_6_")

-- Blocks


-- Sensors events

function sensor_1:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_4_", "door_group_1_")

end

function sensor_2:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_5_", "door_group_1_")

end

function sensor_3:on_activated()

  local skeleton_step = game:get_value("dungeon_5_skeleton_step")
  if skeleton_step == nil then
    skeleton_step = 1
  end
  if skeleton_step == 1 then
    door_manager:close_if_enemies_not_dead(map, "skeleton_1", "door_group_3_")
    sol.audio.play_music("maps/dungeons/small_boss")
  end

end

function sensor_4:on_activated()

  local skeleton_step = game:get_value("dungeon_5_skeleton_step")
  if skeleton_step == nil then
    skeleton_step = 1
  end
  if skeleton_step == 2 then
    door_manager:close_if_enemies_not_dead(map, "skeleton_2", "door_group_4_")
    sol.audio.play_music("maps/dungeons/small_boss")
  end

end

function sensor_5:on_activated()

  local skeleton_step = game:get_value("dungeon_5_skeleton_step")
  if skeleton_step == nil then
    skeleton_step = 1
  end
  if skeleton_step == 3 then
    door_manager:close_if_enemies_not_dead(map, "skeleton_3", "door_group_5_")
    sol.audio.play_music("maps/dungeons/small_boss")
  end

end

function sensor_6:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_22_", "door_group_5_")

end

function sensor_7:on_activated()

  local skeleton_step = game:get_value("dungeon_5_skeleton_step")
  if skeleton_step == nil then
    skeleton_step = 1
  end
  if skeleton_step == 4 then
    door_manager:close_if_enemies_not_dead(map, "skeleton_4", "door_group_6_")
    sol.audio.play_music("maps/dungeons/small_boss")
  end

end

function sensor_8:on_activated()

  if is_boss_active == false then
    is_boss_active = true
    enemy_manager:launch_boss_if_not_dead(map)
  end

end

function sensor_9:on_activated()

  if is_small_boss_active == false then
    is_small_boss_active = true
    enemy_manager:launch_small_boss_if_not_dead(map)
  end

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

function auto_separator_15:on_activating(direction4)
  switch_1:set_activated(false)
  block_group_2_1:reset()
  local x, y = hero:get_position()
  if direction4 == 0 then
    map:close_doors("door_group_4_")
  end
end

function auto_separator_16:on_activating(direction4)
  switch_1:set_activated(false)
  block_group_2_1:reset()
  local x, y = hero:get_position()
  if direction4 == 1 then
    map:close_doors("door_group_4_")
  end
end

function auto_separator_21:on_activating(direction4)
  switch_1:set_activated(false)
  block_group_2_1:reset()
  local x, y = hero:get_position()
  if direction4 == 3 then
    map:close_doors("door_group_4_")
  end
end

function separator_skeleton_1_1:on_activating(direction4)
  map:init_skeletons()
end

function separator_skeleton_1_2:on_activating(direction4)
  map:init_skeletons()
end

function separator_skeleton_2_1:on_activating(direction4)
  map:init_skeletons()
end


function separator_skeleton_3_1:on_activating(direction4)
  map:init_skeletons()
end

function separator_skeleton_3_1:on_activating(direction4)
  map:init_skeletons()
end


function separator_skeleton_4_1:on_activating(direction4)
  map:init_skeletons()
end



separator_manager:manage_map(map)
owl_manager:manage_map(map)

