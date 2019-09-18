--[[
  Lua script of item "pegasus shoes".
  
  This newer version uses plainly the new global command overrides as it depends on not triggering the "item" state
   Because of that, it must **NEVER** be triggered using the built-in method or else it will never finish and sftlock your game.
  The reason is that it would end any custon jumping state, which do trigger when jumping when running, with pontential bad consequences, such as falling into a pit while mid-air
  
--]]
-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")
require("scripts/multi_events")
require("scripts/states/running")

-- Event called when the game is initialized.
function item:on_created()
  self:set_savegame_variable("possession_pegasus_shoes")
  self:set_sound_when_brandished(nil)
  self:set_assignable(true)
  local game = self:get_game()
  game:set_ability("jump_over_water", 0) -- Disable auto-jump on water border.
end

local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", function(game)
    game:register_event("on_command_pressed", function(game, command)
        --Note : there is no "item_X" command check here, since this item has been integrated into the new global command override system.
        if not game:is_suspended() then
          if command == "action" then 
            if game:get_command_effect("action") == nil and game:has_item("pegasus_shoes") then
              local hero=game:get_hero()
              local entity=hero:get_facing_entity() 
              
              if entity and entity:get_type()=="custom_entity" and entity:get_model() == "npc" then --secial case for the custom NPC entity, because it could not interact with
                return 
              end

              local offsets = { {1, 0}, {0, -1}, {-1, 0}, {0, 1} }
              if hero:test_obstacles(unpack(offsets[hero:get_direction() + 1])) or hero:get_state() == "frozen" or hero:get_state()=="swimming" or hero:get_state()=="custom" and not hero:get_state_object():get_can_use_item("pegasus_shoes") then
                return
              end
              -- Caéll custom run script.
              game:get_hero():run()
              return true
            end
          end
        end
      end)
  end)

--This function is automaticelly called by the new global command override system. 
function item:start_using()
  item:get_game():get_hero():run()
end

function item:on_obtaining()

  audio_manager:play_sound("items/fanfare_item_extended")

end