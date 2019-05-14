-- Lua script of map examples/test_map.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest
local map = ...
local game = map:get_game()
local hero = map:get_hero()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()

  -- You can initialize the movement and sprites of various
  -- map entities here.
end
local dummy = require("scripts/states/dummy")
-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()
--  print "DUMMY"
--  dummy(hero)
end
local jumping_manager=require("scripts/jump_manager")

function autojump:on_activated()
  game:set_life(game:get_max_life())
  if hero:is_running()==true then
    jumping_manager.start(hero)
  else
    hero:start_jumping()
  end
end

--Test the interaction between owl cinematic and items
local owl_manager = require("scripts/maps/owl_manager")

function owl_test:on_activated()
  owl_manager:appear(map, 7, function()
      print "Oot hoot"
      sol.audio.stop_music()
    end)  
end


function jump_test_tp:on_activated()
  local x,y=hero:get_position()
  local xa=jump_test_tp:get_position()
  local dx=xa-autojump:get_position()
  hero:set_position(x-dx-16, y+16)
end