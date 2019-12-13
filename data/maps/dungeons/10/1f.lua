-- Lua script of map dungeons/10/1f.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()
local flow_states = {lava = true, gel = false}

-- Include scripts
require("scripts/multi_events")
local door_manager = require("scripts/maps/door_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local separator_manager = require("scripts/maps/separator_manager")
local light_manager = require("scripts/maps/light_manager")

-- Map events
function map:on_started(destination)

  -- Light
  light_manager:init(map)

  -- Enemies
  enemy_manager:set_weak_boo_buddies_when_at_least_on_torch_lit(map, "torch_1", "boo_buddies_1")

  -- Doors
  door_manager:open_when_torches_lit(map, "torch_1", "door_ghost_1")
  door_manager:open_when_enemies_dead(map,  "keese_1",  "door_keese_1")
  door_manager:open_when_enemies_dead(map,  "maskass_1",  "door_maskass_1")

  -- Separators
  separator_manager:init(map)
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

end

-- Init door puzzles in the dungeon
local function init_doors()

  map:set_doors_open("door_keese_1")
  map:set_doors_open("door_horse_puzzle")
end

-- Init pipe puzzle in the dungeon
local function init_pipes()

  if map:get_game():get_value("dungeon_10_lava_is_flowing") == false then
    pipe_disable_flow("lava")
    lava_lever:get_sprite():set_direction(1)
  else
    pipe_enable_flow("lava")
    lava_lever:get_sprite():set_direction(0)
  end

  if map:get_game():get_value("dungeon_10_gel_is_flowing") == false then
    pipe_disable_flow("gel")
    gel_lever:get_sprite():set_direction(1)
  else
    pipe_enable_flow("gel")
    gel_lever:get_sprite():set_direction(0)
  end
end

-- Init all puzzles in the dungeon
local function init_all_puzzles()

  init_doors()
  init_pipes()
end

-- Event called at initialization time, as soon as this map becomes is loaded.
function map:on_started()
  
  init_all_puzzles()
end

-- Enemy room 1
function sensor_enemy_room_1:on_activated()

  map:close_doors("door_keese_1")
  sensor_enemy_room_1:set_enabled(false)
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

sensor_6:register_event("on_activated", function()

  map:set_doors_open("door_group_6_")
end)

sensor_7:register_event("on_activated", function()

  map:close_doors("door_group_6_")
end)