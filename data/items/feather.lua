--[[

  Lua script of item feather.

  This newer version uses plainly the new global command overrides as it depends on not triggering the "item" state
  The reason is that it would end any custon jumping state, with bad consequences, such as falling into a pit while mid-air
  
--]]
local hero_meta = sol.main.get_metatable("hero")
local item = ...
local game = item:get_game()

-- Include scripts
local audio_manager = require("scripts/audio_manager")
require("scripts/states/jumping")
require("scripts/states/jumping_sword")
local jm=require("scripts/jump_manager")
require("scripts/multi_events")

-- Event called when the game is initialized.
function item:on_started()
  item:set_savegame_variable("possession_feather")
  item:set_sound_when_brandished(nil)
  item:set_assignable(true)
end

local game_meta = sol.main.get_metatable("game")

--This function is automatically called when the item command is pressed. it is similar to item:on_using, without state changing 
function item:start_using()

  local hero = game:get_hero()
  local map = game:get_map()
  if hero.is_jumping~=true then
    if not map:is_sideview() then
      
      --in top view maps, we have to account for the terrain, so we need custom states.
      local state = hero:get_state()
      
      --Fun fact : before adding this check, it was possible to glitch through pits by repeatedly jumping while sinking in the hole
      if state ~="falling" then 
        
        --Jump with sword pulled out
        if state == "sword swinging" or state =="sword loading" or state=="custom" and hero:get_state_object():get_description() == "jumping_sword" then 
          hero:start_flying_attack()
        elseif state=="custom" and hero:get_state_object():get_description()=="running" then 
          --Run'n'jump! 
          --Note : In Diarandor's version, it wound have required three seperate states: one for running,, one for jumping, AND one for run'n'jumping, now we can just use apply the jump effect to the running state. 
          jm.start(hero)
        else
          hero:start_jumping()
        end
      end
    else
      --In side view maps, we don't have to care about the terrain and movement, which is already handled by the sideview manager, so all we have do to is apply a vertical impulsion to the hero.
      local vspeed = hero.vspeed or 0
      if vspeed == 0 or map:get_ground(hero:get_position())=="deep_water" then
--        print "validated, now jump :"
        audio_manager:play_sound("hero/jump")
        sol.timer.start(10, function()
            hero.on_ladder = false
            hero.vspeed = -4
          end)
      end
    end
  end
end

--Theorically, we cold entierely remove this event, but in the perspective of reusine this item in other projects, it is a perfect tool to check your configuration. 
function item:on_using()
  print "this message should never appear. If it does, then check your dependancies")

  -- Define here what happens when using this item
  -- and call item:set_finished() to release the hero when you have finished.
  item:set_finished()
end


function item:on_obtaining()

  audio_manager:play_sound("items/fanfare_item_extended")

end
