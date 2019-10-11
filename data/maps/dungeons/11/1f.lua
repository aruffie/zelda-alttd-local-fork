-- Lua script of map dungeons/11/1f.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()
local light_manager = require("scripts/maps/light_manager")
local audio_manager = require("scripts/audio_manager")

function map:on_started()
  light_manager:init(map)
  map:set_light(0)
  audio_manager:stop_music()
  --audio_manager:play_music("74_wind_fish_egg")
end


function map:on_opening_transition_finished()

end
