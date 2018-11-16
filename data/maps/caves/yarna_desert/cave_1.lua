-- Lua script of map caves/egg_of_the_dream_fish/cave_1.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()
local separator_manager = require("scripts/maps/separator_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events
function map:on_started(destination)

  -- Music
  map:init_music()
  
end

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("18_cave")

end

separator_manager:manage_map(map)


--Weak doors play secret sound on opened
function weak_door_1:on_opened()
  
  sol.audio.play_sound("secret_1")
  
end