local map = ...
local game = map:get_game()
local hero = map:get_hero()


--DEBUG: lauch a dummy state for engine bug hunting.
local dummy = require("scripts/states/dummy")
function map:on_opening_transition_finished()
--  print "DUMMY"
--  dummy(hero)
end

--DEBUG: Jumping state debug test utility, for consistent measures
local jumping_manager=require("scripts/jump_manager")
function autojump:on_activated()
  game:set_life(game:get_max_life())
  if hero:is_running()==true then
    jumping_manager.start(hero)
  else
    hero:jump()
  end
end
-- put the hero at the newt jump test line. Part of the jump state debug tests.
function jump_test_tp:on_activated()
  local x,y=hero:get_position()
  local xa=jump_test_tp:get_position()
  local dx=xa-autojump:get_position()
  hero:set_position(x-dx-16, y+16)
end

--DEBUG: Test the interaction between owl cinematic and items
local owl_manager = require("scripts/maps/owl_manager")

function owl_test:on_activated()
  owl_manager:appear(map, 7, function()
      print "Oot hoot"
      sol.audio.stop_music()
    end)  
end