-- Variables
local map = ...
local separator = ...
local game = map:get_game()
local is_small_boss_active = false
local is_boss_active = false

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local door_manager = require("scripts/maps/door_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local flying_tile_manager = require("scripts/maps/flying_tile_manager")
local owl_manager = require("scripts/maps/owl_manager")
local separator_manager = require("scripts/maps/separator_manager")
local switch_manager = require("scripts/maps/switch_manager")
local treasure_manager = require("scripts/maps/treasure_manager")

-- Map events
function map:on_started()

  -- Chests
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_map",  "dungeon_6_map")
  treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_5_", "chest_map")
  -- Doors
  map:set_doors_open("door_group_1", true)
  map:set_doors_open("door_group_3", true)
  map:set_doors_open("door_group_7", true)
  map:set_doors_open("door_group_18", true)
  map:set_doors_open("door_group_19", true)
  map:set_doors_open("door_group_20", true)
  door_manager:open_weak_wall_if_savegame_exist(map, "weak_wall_group_1_", "dungeon_6_weak_wall_group_1")
  door_manager:open_weak_wall_if_savegame_exist(map, "weak_wall_group_15_", "dungeon_6_weak_wall_group_15")
  door_manager:open_when_flying_tiles_dead(map,  "enemy_group_11_enemy",  "door_group_7_")
  door_manager:open_when_switch_activated(map,  "switch_1",  "door_group_2_")
  door_manager:open_when_pot_break(map, "door_group_3_")
  door_manager:open_when_pot_break(map, "door_group_5_")
  door_manager:open_when_pot_break(map, "door_group_6_")
  door_manager:open_when_pot_break(map, "door_group_8_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_1_",  "door_group_1_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_2_",  "door_group_4_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_12_",  "door_group_8_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_12_",  "door_group_10_", false)
  door_manager:open_when_enemies_dead(map,  "enemy_group_12_",  "door_group_17_", false)
  door_manager:open_when_enemies_dead(map,  "enemy_group_26_",  "door_group_18")
  door_manager:open_when_enemies_dead(map,  "enemy_group_26_",  "door_group_20_", false)
  door_manager:open_when_enemies_dead(map,  "enemy_group_27_",  "door_group_19_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_27_",  "door_group_20_", false)
  -- Enemies
  enemy_manager:create_teletransporter_if_small_boss_dead(map, false)
  -- Music
  game:play_dungeon_music()
  -- Owl
  owl_manager:init(map)
  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_small_key_1")
  treasure_manager:disappear_pickable(map, "pickable_small_key_2")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_9_", "pickable_small_key_1")
  treasure_manager:appear_pickable_when_flying_tiles_dead(map, "enemy_group_29_enemy", "pickable_small_key_2")
  treasure_manager:appear_heart_container_if_boss_dead(map)
  -- Separators
  separator_manager:init(map)

end

function map:on_opening_transition_finished(destination)

  if destination == dungeon_6_1_B then
    game:start_dialog("maps.dungeons.6.welcome")
  end

end

function map:on_obtaining_treasure(item, variant, savegame_variable)

  if savegame_variable == "dungeon_6_big_treasure" then
    treasure_manager:get_instrument(map)
  end

end

-- Doors events
weak_wall_group_1:register_event("on_opened", function()
    
  door_manager:destroy_wall(map, "weak_wall_group_1_")
  
end)

-- Sensors events
function sensor_1:on_activated()

  flying_tile_manager:init(map, "enemy_group_11")

end

function sensor_2:on_activated()

  if flying_tile_manager.is_launch == false then
    map:close_doors("door_group_7")
    flying_tile_manager:launch(map, "enemy_group_11")
 end

end

function sensor_3:on_activated()

  flying_tile_manager:reset(map, "enemy_group_11")

end

function sensor_4:on_activated()

  flying_tile_manager:init(map, "enemy_group_11")
  map:set_doors_open("door_group_8", true)

end

function sensor_5:on_activated()

  if flying_tile_manager.is_launch == false then
    map:close_doors("door_group_7")
    flying_tile_manager:launch(map, "enemy_group_11")
 end

end

function sensor_6:on_activated()

  flying_tile_manager:reset(map, "enemy_group_11")
  local direction4 = hero:get_direction()
  if direction4 == 1 then
    map:close_doors("door_group_8")
  end

end

function sensor_7:on_activated()

  local direction4 = hero:get_direction()
  if direction4 == 0 then
    door_manager:close_if_enemies_not_dead(map, "enemy_group_12", "door_group_8")
    door_manager:close_if_enemies_not_dead(map, "enemy_group_12", "door_group_10")
    door_manager:close_if_enemies_not_dead(map, "enemy_group_12", "door_group_17")
  end

end

function sensor_8:on_activated()

  local direction4 = hero:get_direction()
  if direction4 == 3 then
    door_manager:close_if_enemies_not_dead(map, "enemy_group_12", "door_group_8")
    door_manager:close_if_enemies_not_dead(map, "enemy_group_12", "door_group_10")
    door_manager:close_if_enemies_not_dead(map, "enemy_group_12", "door_group_17")
  end

end

function sensor_9:on_activated()

  local direction4 = hero:get_direction()
  if direction4 == 1 then
    door_manager:close_if_enemies_not_dead(map, "enemy_group_12", "door_group_8")
    door_manager:close_if_enemies_not_dead(map, "enemy_group_12", "door_group_10")
    door_manager:close_if_enemies_not_dead(map, "enemy_group_12", "door_group_17")
  end

end

function sensor_10:on_activated()

  flying_tile_manager:reset(map, "enemy_group_11")
  map:set_doors_open("door_group_8", true)
  map:set_doors_open("door_group_10", true)
  map:set_doors_open("door_group_17", true)
  local direction4 = hero:get_direction()
  if direction4 == 1 then
      map:close_doors("door_group_8")
  end

end

function sensor_11:on_activated()

  map:set_doors_open("door_group_8", true)
  map:set_doors_open("door_group_10", true)
  map:set_doors_open("door_group_17", true)

end


function sensor_12:on_activated()

  map:set_doors_open("door_group_8", true)
  map:set_doors_open("door_group_10", true)
  map:set_doors_open("door_group_17", true)

end

function sensor_13:on_activated()

  local x,y = infinite_hallway:get_position()
  hero:set_position(x,y)

end

function sensor_16:on_activated()

  flying_tile_manager:reset(map, "enemy_group_29")
  treasure_manager:disappear_pickable(map, "pickable_small_key_2")

end

function sensor_17:on_activated()

  flying_tile_manager:init(map, "enemy_group_29")

end

function sensor_18:on_activated()

  flying_tile_manager:launch(map, "enemy_group_29")

end

function sensor_19:on_activated()

  flying_tile_manager:launch(map, "enemy_group_29")

end

function sensor_20:on_activated()

  flying_tile_manager:reset(map, "enemy_group_29")

end

function sensor_21:on_activated()

  flying_tile_manager:init(map, "enemy_group_29")

end

function sensor_22:on_activated()

  flying_tile_manager:launch(map, "enemy_group_29")

end

function sensor_23:on_activated()

    door_manager:close_if_enemies_not_dead(map, "enemy_group_26", "door_group_18")
    door_manager:close_if_enemies_not_dead(map, "enemy_group_26", "door_group_20")

end

function sensor_24:on_activated()

    door_manager:close_if_enemies_not_dead(map, "enemy_group_26", "door_group_18")
    door_manager:close_if_enemies_not_dead(map, "enemy_group_26", "door_group_20")

end

function sensor_25:on_activated()

    door_manager:close_if_enemies_not_dead(map, "enemy_group_26", "door_group_19")
    door_manager:close_if_enemies_not_dead(map, "enemy_group_26", "door_group_20")

end

function sensor_26:on_activated()

    door_manager:close_if_enemies_not_dead(map, "enemy_group_27", "door_group_19")
    door_manager:close_if_enemies_not_dead(map, "enemy_group_27", "door_group_20")

end

-- Separator events
auto_separator_14:register_event("on_activating", function(separator, direction4)
    
  if direction4 == 0 then
    map:set_light(0)
  end
  
end)

auto_separator_14:register_event("on_activated", function(separator, direction4)

  if direction4 ~= 0 then
    map:set_light(1)
  end
  
end)

auto_separator_16:register_event("on_activating", function(separator, direction4)

  map:set_doors_open("door_group_3", true)
  if direction4 == 1 then
    sol.timer.start(map, 500, function()
      map:close_doors("door_group_3")
    end)
  end
end)

auto_separator_17:register_event("on_activating", function(separator, direction4)

  map:set_doors_open("door_group_1", true)
  if direction4 == 2 then
    sol.timer.start(map, 500, function()
      door_manager:close_if_enemies_not_dead(map, "enemy_group_1", "door_group_1")
    end)
  end
  
end)