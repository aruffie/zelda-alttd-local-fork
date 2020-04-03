-- Variables
local map = ...
local game = map:get_game()
local is_small_boss_active = false -- Todo small boss implementation
local is_boss_active = false -- Todo boss implementation
local flow_states = {lava = true, gel = false}

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")
local door_manager = require("scripts/maps/door_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local light_manager = require("scripts/maps/light_manager")
local separator_manager = require("scripts/maps/separator_manager")
local switch_manager = require("scripts/maps/switch_manager")
local treasure_manager = require("scripts/maps/treasure_manager")
local flying_tile_manager = require("scripts/maps/flying_tile_manager")

-- Map events
function map:on_started(destination)

  -- Doors
  door_manager:open_when_torches_lit(map, "torch_1", "door_ghost_1")
  door_manager:open_when_enemies_dead(map, "keese_1",  "door_keese_1")
  door_manager:open_when_enemies_dead(map, "maskass_1",  "door_maskass_1")
  door_manager:open_when_enemies_dead(map, "blob_1", "door_blob_1")

  -- Enemies
  enemy_manager:set_weak_boo_buddies_when_at_least_on_torch_lit(map, "torch_1", "boo_buddies_1")

  -- Light
  light_manager:init(map)

  -- Music
  game:play_dungeon_music()

  -- Puzzles
  map:init_all_puzzles()
  
  -- Separators
  separator_manager:init(map)

  -- Treasures
  treasure_manager:appear_chest_when_enemies_dead(map, "hardhat_1", "compass_chest")
  treasure_manager:appear_chest_when_enemies_dead(map, "helmasaur_a", "dungeon_10_map_chest")
  treasure_manager:appear_chest_when_enemies_dead(map, "evil_tile_group_1", "dungeon_10_small_key_chest_3")
end

local function handle_solid_lava()

  if flow_states["gel"] == true and flow_states["lava"] == true then
    for wall in map:get_entities("solid_lava_wall") do
      wall:set_enabled(false)
    end 
    tile_solid_lava:set_enabled(true)
  else
    for wall in map:get_entities("solid_lava_wall") do
      wall:set_enabled(true)
    end 
    tile_solid_lava:set_enabled(false)
  end
end

-- Enable pipe flow of the given type
local function pipe_enable_flow(type)

  for pipe in map:get_entities("pipe_" .. type) do
    pipe:get_sprite():set_paused(false)
  end

  flow_states[type] = true

  for pond in map:get_entities(type .. "_pond") do
    pond:set_enabled(true)
  end

  map:get_game():set_value("dungeon_10_" .. type .. "_is_flowing", true)

  handle_solid_lava()
end

-- Disable pipe flow of the given type
local function pipe_disable_flow(type)

  for pipe in map:get_entities("pipe_" .. type) do
    pipe:get_sprite():set_paused(true)
  end

  flow_states[type] = false

  for pond in map:get_entities(type .. "_pond") do
    pond:set_enabled(false)
  end

  map:get_game():set_value("dungeon_10_" .. type .. "_is_flowing", false)

  handle_solid_lava()
end

-- Init door puzzles in the dungeon
local function init_doors()

  map:set_doors_open("door_keese_1")
  map:set_doors_open("door_horse_puzzle")
  
end

-- Init pipe puzzle in the dungeon
local function init_pipes()

  if map:get_game():get_value("dungeon_10_lava_is_flowing") ~= true then
    pipe_disable_flow("lava")
    lava_lever:get_sprite():set_direction(1)
  else
    pipe_enable_flow("lava")
    lava_lever:get_sprite():set_direction(0)
  end

  if map:get_game():get_value("dungeon_10_gel_is_flowing") ~= true then
    pipe_disable_flow("gel")
    gel_lever:get_sprite():set_direction(1)
  else
    pipe_enable_flow("gel")
    gel_lever:get_sprite():set_direction(0)
  end
  
end

function init_chests()

  if game:get_value("dungeon_10_compass") ~= true then
    compass_chest:set_enabled(false)
  end

  if game:get_value("dungeon_10_map_chest") ~= true then
    dungeon_10_map_chest:set_enabled(false)
  end

  if game:get_value("dungeon_10_small_key_chest_3") ~= true then
    dungeon_10_small_key_chest_3:set_enabled(false)
  end
end

-- Init all puzzles in the dungeon
function map:init_all_puzzles()

  init_doors()
  init_pipes()
  init_chests()
  handle_solid_lava()
  
end

lava_lever:register_event("on_activated", function()

  if lava_lever:get_sprite():get_direction() == 0 then
    pipe_enable_flow("lava")
  else
    pipe_disable_flow("lava")
  end
end)

gel_lever:register_event("on_activated", function()

  if gel_lever:get_sprite():get_direction() == 0 then
    pipe_enable_flow("gel")
  else
    pipe_disable_flow("gel")
  end
  
end)

sensor_keese_1:register_event("on_activated", function()

  door_manager:close_if_enemies_not_dead(map, "keese_1", "door_keese_1")
end)

sensor_blob_1:register_event("on_activated", function()

  door_manager:close_if_enemies_not_dead(map, "blob_1", "door_blob_1")
end)

sensor_open_blob_1:register_event("on_activated", function()

  map:set_doors_open("door_blob_1")
end)

switch_1:register_event("on_activated", function()

  map:open_doors("door_switch_1")
  audio_manager:play_sound("misc/secret1")
end)

sensor_switch_1:register_event("on_activated", function()

  if not switch_1:is_activated() then
    map:close_doors("door_switch_1")
  end
end)

sensor_open_switch_1:register_event("on_activated", function()

  map:set_doors_open("door_switch_1")
end)

sensor_6:register_event("on_activated", function()

  map:set_doors_open("door_group_6_")
end)

sensor_7:register_event("on_activated", function()

  map:close_doors("door_group_6_")
end)

flying_tile_sensor:register_event("on_activated", function()

  if flying_tile_manager.is_launch == false then
    flying_tile_manager:init(map, "evil_tile_group")
    flying_tile_manager:launch(map, "evil_tile_group")
  end
end)