-- Variables
local map = ...
local separator = ...
local game = map:get_game()
local is_small_boss_active = false
local is_boss_active = false
local master_stalfos_step
local master_stalfos_life -- Keep the enemy life in a global cause it can be hurt while escaping from a step, then the next one will need one hurt less.

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")
local door_manager = require("scripts/maps/door_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local switch_manager = require("scripts/maps/switch_manager")
local treasure_manager = require("scripts/maps/treasure_manager")
local separator_manager = require("scripts/maps/separator_manager")

-- Master Stalfos appearing.
local function appear_master_stalfos(placeholder, on_escaping_callback)

  local x, y, layer = placeholder:get_position()
  placeholder:set_enabled(false)

  -- Create the Master Stalfos, update its life and make it fall from the ceiling.
  local enemy = map:create_enemy{
    name = "master_stalfos",
    breed = "boss/master_stalfos",
    direction = 2,
    x = x,
    y = y,
    layer = layer,
    treasure_name = placeholder:get_property("treasure")
  }
  enemy:set_life(master_stalfos_life)
  enemy:start_falling(placeholder:get_property("falling_dialog"))

  -- Make the enemy escape when the life is under the minimum for this step.
  enemy:register_event("on_hurt", function(enemy)
    master_stalfos_life = enemy:get_life()
    if master_stalfos_life <= (tonumber(placeholder:get_property("escaping_life")) or -1) then
      enemy:start_escaping("maps.dungeons.5.master_stalfos_escaping", function()
        master_stalfos_step = master_stalfos_step + 1
        game:set_value("dungeon_5_master_stalfos_step", master_stalfos_step)
        on_escaping_callback()
      end)
    end
  end)

  -- Increase the step on enemy dead.
  enemy:register_event("on_dead", function(enemy)
    master_stalfos_step = master_stalfos_step + 1
    game:set_value("dungeon_5_master_stalfos_step", master_stalfos_step)
  end)
  
  audio_manager:play_music("small_boss")
end

-- Map events
map:register_event("on_started", function()

  -- Chests
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_beak_of_stone",  "dungeon_5_beak_of_stone")
  treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_10_", "chest_beak_of_stone")
  -- Doors
  map:set_doors_open("door_group_6_", true)
  door_manager:open_when_enemies_dead(map,  "enemy_group_5_",  "door_group_1_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_4_",  "door_group_1_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_9_",  "door_group_2_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_11_",  "door_group_3_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_20_",  "door_group_5_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_22_",  "door_group_5_")
  -- Enemies
  enemy_manager:create_teletransporter_if_small_boss_dead(map, false)
  -- Music
  game:play_dungeon_music()
  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_small_key_1")
  treasure_manager:appear_pickable_when_blocks_moved(map, "auto_block_group_1_", "pickable_small_key_1")
  treasure_manager:appear_heart_container_if_boss_dead(map)
  -- Separators
  separator_manager:init(map)
  
  -- Display blocks in master stalfos room as flat entities because the boss is displayed as flat and should be displayed over them.
  for block in map:get_entities("master_stalfos_block") do
    block:set_drawn_in_y_order(false)
    block:bring_to_back()
  end

  -- Fill Master Stalfos globals in case reentering the dungeon.
  master_stalfos_step = game:get_value("dungeon_5_master_stalfos_step") or 1
  master_stalfos_life = 12 - (master_stalfos_step - 1) * 3
end)

function map:on_obtaining_treasure(item, variant, savegame_variable)

  if savegame_variable == "dungeon_5_big_treasure" then
    treasure_manager:get_instrument(map)
  end

end

-- Sensors events
function sensor_1:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_4_", "door_group_1_")

end

function sensor_2:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_5_", "door_group_1_")

end

function sensor_3:on_activated()

  if master_stalfos_step == 1 then
    sensor_3:set_enabled(false)
    map:close_doors("door_group_3_")
    appear_master_stalfos(placeholder_skeleton, function()
      map:open_doors("door_group_3_")
    end)
  end
end

function sensor_4:on_activated()

  if master_stalfos_step == 2 then
    sensor_4:set_enabled(false)
    map:close_doors("door_group_4_")
    appear_master_stalfos(placeholder_skeleton_2, function()
      map:open_doors("door_group_4_")
    end)
  end
end

function sensor_5:on_activated()

  if master_stalfos_step == 3 then
    sensor_5:set_enabled(false)
    map:close_doors("door_group_5_")
    appear_master_stalfos(placeholder_skeleton_3, function()
      map:open_doors("door_group_5_")
    end)
  end
end

function sensor_6:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_22_", "door_group_5_")

end

function sensor_7:on_activated()

  if master_stalfos_step == 4 then
    sensor_7:set_enabled(false)
    map:close_doors("door_group_6_")
    appear_master_stalfos(placeholder_skeleton_4, function()
      map:open_doors("door_group_6_")
    end)
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

function sensor_10:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_26_", "door_group_small_boss")

end

-- Switchs events
function switch_1:on_activated()

  map:open_doors("door_group_4")
  audio_manager:play_sound("misc/secret1")

end

-- Chests events
function chest_hookshot_fail:on_opened()

  game:start_dialog("maps.dungeons.5.chest_hookshot_fail", function()
    hero:unfreeze()
  end)

end
