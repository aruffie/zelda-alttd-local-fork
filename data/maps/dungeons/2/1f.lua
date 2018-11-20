-- Variables
local map = ...
local separator = ...
local game = map:get_game()
local is_small_boss_active = false
local is_boss_active = false
local boss_key_enemies_index = 0

-- Include scripts
require("scripts/multi_events")
local door_manager = require("scripts/maps/door_manager")
local treasure_manager = require("scripts/maps/treasure_manager")
local switch_manager = require("scripts/maps/switch_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local light_manager = require("scripts/maps/light_manager")
local separator_manager = require("scripts/maps/separator_manager")
local owl_manager = require("scripts/maps/owl_manager")

-- Map events
function map:on_started()

  -- Music
  game:play_dungeon_music()
  -- Light
  light_manager:init(map)
  -- Owl
  owl_manager:init(map)
  -- Chests
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_compass",  "dungeon_2_compass")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_small_key_4",  "dungeon_2_small_key_4")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_power_bracelet",  "dungeon_2_power_bracelet")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_boss_key",  "dungeon_2_boss_key")
  -- Blocks
  map:init_block_group_1()
  -- Ennemies
  enemy_manager:create_teletransporter_if_small_boss_dead(map, false)
  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_small_key_1")
  treasure_manager:disappear_pickable(map, "pickable_small_key_2")
  treasure_manager:disappear_pickable(map, "heart_container")
  -- Switchs
  switch_manager:activate_switch_if_savegame_exist(map, "switch_1",  "dungeon_2_small_key_4")

end

function map:on_opening_transition_finished(destination)
  
  if destination == dungeon_2_1_B then
    game:start_dialog("maps.dungeons.2.welcome")
  end
  map:set_doors_open("door_group_4_", true)
  map:set_doors_open("door_group_small_boss", true)
  
end

function map:on_obtaining_treasure(item, variant, savegame_variable)

  if savegame_variable == "dungeon_2_big_treasure" then
    treasure_manager:get_instrument(map)
  end

end

function map:init_block_group_1()
  
  if game:get_value("dungeon_2_wall_1") then
    for entity in map:get_entities("wall_1_") do
      entity:remove()
    end
  else
    local remaining = map:get_entities_count("block_group_1_")
    local function block_on_moved()
      remaining = remaining - 1
      if remaining == 0 then
        map:launch_cinematic_1()
     end
    end
    for block in map:get_entities("block_group_1_") do
      block.on_moved = block_on_moved
    end
  end
  
end

-- Doors events
door_manager:open_when_torches_lit(map, "auto_torch_group_1_", "door_group_1_")
door_manager:open_when_enemies_dead(map,  "enemy_group_8_",  "door_group_4_")
door_manager:open_when_enemies_dead(map,  "enemy_group_16_",  "door_group_3_")

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

-- Sensors events
function sensor_1:on_activated()

  if is_small_boss_active == false then
    is_small_boss_active = true
    enemy_manager:launch_small_boss_if_not_dead(map)
  end

end

function sensor_2:on_activated()

  if is_small_boss_active == false then
    is_small_boss_active = true
    enemy_manager:launch_small_boss_if_not_dead(map)
  else
    map:close_doors("door_group_small_boss_1")
    map:close_doors("door_group_small_boss_2")
  end

end

function sensor_3:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_8_", "door_group_4_")

end

function sensor_4:on_activated()

  if is_boss_active == false then
    is_boss_active = true
    enemy_manager:launch_boss_if_not_dead(map)
  end

end

-- Separators events
auto_separator_2:register_event("on_activated", function(separator, direction4)

  map:set_light(0)

end)

auto_separator_4:register_event("on_activating", function(separator, direction4)
  local x, y = hero:get_position()
  if direction4 == 2 then
    map:set_light(0)
  end
end)

auto_separator_4:register_event("on_activated", function(separator, direction4)

  if direction4 ~= 2 then
    map:set_light(1)
  end
end)

auto_separator_11:register_event("on_activating", function(separator, direction4)
  local x, y = hero:get_position()
  if direction4 == 1 then
    map:set_light(0)
  end
end)

auto_separator_11:register_event("on_activated", function(separator, direction4)

  if direction4 ~= 1 then
    map:set_light(1)
  end
end)

auto_separator_21:register_event("on_activated", function(separator, direction4)

    map:set_light(0)

end)

auto_separator_25:register_event("on_activating", function(separator, direction4)
  local x, y = hero:get_position()
  if direction4 == 2 then
    map:set_light(0)
  end
end)

auto_separator_25:register_event("on_activated", function(separator, direction4)

  if direction4 ~= 2 then
    map:set_light(1)
  end
end)

function auto_separator_26:on_activating(direction4)
  
  block_group_1_1:reset()
  block_group_1_2:reset()
  
end

-- Switchs events
function switch_1:on_activated()

  treasure_manager:appear_chest(map, "chest_small_key_4", true)

end

-- Treasures events
treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_2_", "pickable_small_key_1")
treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_5_", "pickable_small_key_2")
treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_3_", "chest_compass")
treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_17_", "chest_power_bracelet")


-- Cinematics
-- This is the cinematic that the hero push "block_group_1" blocks
function map:launch_cinematic_1()
  
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero}
    }
    map:set_cinematic_mode(true, options)
    sol.audio.stop_music()
    wait(2000)
    sol.audio.play_sound("shake")
    local camera = map:get_camera()
    local shake_config = {
        count = 32,
        amplitude = 4,
        speed = 90
    }
    wait_for(camera.shake,camera,shake_config)
    sol.audio.play_sound("explosion")
    local x,y,layer = placeholder_explosion_wall_1:get_position()
    map:create_explosion({
      x = x,
      y = y,
      layer = layer
    })
    map:create_explosion({
      x = x - 8,
      y = y - 8,
      layer = layer
    })
    map:create_explosion({
      x = x + 8,
      y = y + 8,
      layer = layer
    })
    for entity in map:get_entities("wall_1_") do
      entity:remove()
    end
    wait(1000)
    sol.audio.play_sound("secret_1")
    game:play_dungeon_music()
    game:set_value("dungeon_2_wall_1", true)
    map:set_cinematic_mode(false, options)
  end)
end

-- Separators
separator_manager:init(map)
