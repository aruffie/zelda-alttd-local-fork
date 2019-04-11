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
local max_yvel = 5
require("scripts/states/jump")
require("scripts/states/flying_sword")

-- Event called when the game is initialized.
function item:on_started()
  item:set_savegame_variable("possession_feather")
  item:set_sound_when_brandished(nil)
  item:set_assignable(true)
  -- Initialize the properties of your item here,
  -- like whether it can be saved, whether it has an amount
  -- and whether it can be assigned.
end

require("scripts/multi_events")
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_command_pressed", function(game, command)
    print ("command ? > "..command)
    local item_1=game:get_item_assigned("1")
    local item_2=game:get_item_assigned("2")
    if command=="item_1" and item_1 and item_1:get_name()=="feather"
    or command=="item_2" and item_2 and item_2:get_name()=="feather" then
      print "manually jumping"
      --  print "FEATHER TIME"
      local hero = game:get_hero()
      local map = game:get_map()
      if hero.is_jumping~=true then
        if not map:is_sideview() then
          --é print "ok"
          local state = hero:get_state()
          if state ~= "sword swinging" and state ~="sword loading" then 
            hero:start_jumping()
          else
            hero:start_flying_attack()
          end
        else
--      print "SIDEVIEW JUMP requested "
          local vspeed = hero.vspeed or 0
          if vspeed == 0 or map:get_ground(hero:get_position())=="deep_water" then
--        print "validated, now jump :"
            sol.timer.start(10, function()
                hero.on_ladder = false
                hero.vspeed = -max_yvel
              end)
          end
        end
      end

      return true
    end
  end)



function item:on_using()
  print "this message should not be displayed if i am correct"

  -- Define here what happens when using this item
  -- and call item:set_finished() to release the hero when you have finished.
  item:set_finished()
end
