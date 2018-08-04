-- Lua script of map dungeons/10/1f.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map becomes is loaded.
function map:on_started()
  
  map:set_doors_open("door_enemy_1")
  map:set_doors_open("door_horse_puzzle")
end

-- Enemy room 1
function sensor_enemy_room_1:on_activated()

  map:close_doors("door_enemy_1")
end

-- TEST ONLY
function pipe_button:on_activated()
 
  for pipe in map:get_entities("pipe_a") do
    pipe:get_sprite():set_animation("flowing")
  end

  for pipe in map:get_entities("pipe_g") do
    pipe:get_sprite():set_animation("flowing")
  end
end