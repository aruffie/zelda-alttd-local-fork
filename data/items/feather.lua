-- Lua script of item feather.
-- This script is executed only once for the whole game.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local hero_meta = sol.main.get_metatable("hero")
local item = ...
local game = item:get_game()
--local hero = game:get_hero()

-- Include scripts
local audio_manager = require("scripts/audio_manager")
require("scripts/states/jump")
require("scripts/states/flying_sword")
local jm=require("scripts/jump_manager")
require("scripts/multi_events")

-- Event called when the game is initialized.
function item:on_started()
  item:set_savegame_variable("possession_feather")
  item:set_sound_when_brandished(nil)
  item:set_assignable(true)
  -- Initialize the properties of your item here,
  -- like whether it can be saved, whether it has an amount
  -- and whether it can be assigned.
end

local game_meta = sol.main.get_metatable("game")


game_meta:register_event("on_started", function(game)

    game:register_event("on_command_pressed", function(game, command)
        --print ("command ? > "..command)
        local item_1=game:get_item_assigned(1)
        local item_2=game:get_item_assigned(2)
        if command=="item_1" and item_1 and item_1:get_name()=="feather"
        or command=="item_2" and item_2 and item_2:get_name()=="feather" then
          if not game:is_paused() then
            audio_manager:play_sound("hero/jump")
            --print "manually jumping"
            --  print "FEATHER TIME"
            local hero = game:get_hero()
            local map = game:get_map()
            if hero.is_jumping~=true then
              if not map:is_sideview() then
                -- print "ok"
                local state = hero:get_state()
                if state ~="falling" then
                  if state == "sword swinging" or state =="sword loading" or state=="custom" and hero:get_state_object():get_description() == "flying_sword" then 
                    hero:start_flying_attack()
                  elseif state=="custom" and hero:get_state_object():get_description()=="running" then 
                    jm.start(hero)
                  else
                    hero:start_jumping()
                  end
                end
              else
--      print "SIDEVIEW JUMP requested "
                local vspeed = hero.vspeed or 0
                if vspeed == 0 or map:get_ground(hero:get_position())=="deep_water" then
--        print "validated, now jump :"
                  sol.timer.start(10, function()
                      hero.on_ladder = false
                      hero.vspeed = -5
                    end)
                end
              end
            end
            --Don"t propagate the input or else we will trigger the "item", which would ruin the purpose of the custom states 
            return true
          end
        end
      end)
  end)


function item:on_using()
  print "this message should not be displayed if i am correct"

  -- Define here what happens when using this item
  -- and call item:set_finished() to release the hero when you have finished.
  item:set_finished()
end


function item:on_obtaining()

  audio_manager:play_sound("items/fanfare_item_extended")

end
