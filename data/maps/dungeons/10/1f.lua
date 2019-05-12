-- Lua script of map dungeons/10/1f.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()
local door_manager = require("scripts/maps/door_manager")
local enemy_manager = require("scripts/maps/enemy_manager")

door_manager:open_when_enemies_dead(map,  "keese_1",  "door_keese_1")
door_manager:open_when_enemies_dead(map,  "maskass_1",  "door_maskass_1")

-- Enable pipe flow of the given type
local function pipe_enable_flow(type)

  for pipe in map:get_entities("pipe_" .. type) do
    pipe:get_sprite():set_animation("flowing")
  end
end

-- Disable pipe flow of the given type
local function pipe_disable_flow(type)

  for pipe in map:get_entities("pipe_" .. type) do
    pipe:get_sprite():set_animation("not_flowing")
  end
end

-- Init door puzzles in the dungeon
local function init_doors()

  map:set_doors_open("door_keese_1")
  map:set_doors_open("door_horse_puzzle")
end

-- Init pipe puzzle in the dungeon
local function init_pipes()

  pipe_disable_flow("lava")
  pipe_disable_flow("gel")
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
