local map = ...
local game = map:get_game()
local hero = map:get_hero()


--DEBUG: lauch a dummy state for engine bug hunting.
local dummy = require("scripts/states/dummy")
--function map:on_opening_transition_finished()
--  dummy(hero)
--end

--DEBUG: Jumping state debug test utility, for consistent measures
local jumping_manager=require("scripts/maps/jump_manager")
function autojump:on_activated()
  game:set_life(game:get_max_life())
--  if hero:is_running()==true then
    jumping_manager.start(hero)
--  else
--    hero:jump()
--  end
end
-- put the hero at the newt jump test line. Part of the jump state debug tests.
function jump_test_tp:on_activated()
  local x,y=hero:get_position()
  local xa=jump_test_tp:get_position()
  local dx=xa-autojump:get_position()
  hero:set_position(x-dx-16, y+16)
end

-- put the hero at the newt jump test line. Part of the jump state debug tests.
function drop_test:on_activated()
  --hero.ceiling_drop_sprite_direction=hero:get_sprite():get_direction()
  hero:fall_from_ceiling(127, "hero/jump", function()
      --hero:get_sprite():set_direction(hero.ceiling_drop_sprite_direction)
  end)
end
  

--DEBUG: Test the interaction between owl cinematic and items
local owl_manager = require("scripts/maps/owl_manager")

function owl_test:on_activated()
  owl_manager:appear(map, 7, function()
     --debug_print "Oot hoot"
      sol.audio.stop_music()
    end)  
end
local dummy_timer=false
function dummy_stream_test:on_activated()

  if not dummy_timer then
    dummy(hero)
    dummy_timer=sol.timer.start(map, 500, function()
      hero:unfreeze()
      sol.timer.start(map, 50, function()
        dummy(hero)
        end)
      return true
    end)
  end
end