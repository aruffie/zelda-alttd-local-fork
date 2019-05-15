-- Lua script of item "pegasus shoes".
-- This script is executed only once for the whole game.

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
  -- Redefine event game.on_command_pressed.
  local game = self:get_game()
  game:set_ability("jump_over_water", 0) -- Disable auto-jump on water border.
end

local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", function(game)
    game:register_event("on_command_pressed", function(game, command)
--        print "run command ?"
        if not game:is_suspended() then
--          print "basic check OK"
          local hero = game:get_hero()
          if command == "action" then 
--            print "AAAaaand... ACTION !"
            if game:get_command_effect("action") == nil and game:has_item("pegasus_shoes") then
--              print "THIS IS TEH ATCION URN"
              hero:run()-- Call custom run script.
              return true
            end
          end
        end
      end)
  end)

function item:start_using()
  print "run 2.0"
  item:get_game():get_hero():run()
end

function item:on_obtaining()

  audio_manager:play_sound("items/fanfare_item_extended")

end

function item:on_variant_changed(variant)

--  self:get_game():set_ability("run", variant)

end

function item:on_using()
  print "if this message ever displays, then the dev has screwed up his command handling :)"

end
