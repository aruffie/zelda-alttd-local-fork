-- Lua script of item "acorn".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Event called when the game is initialized.
function item:on_created()
  
  item:set_sound_when_brandished(nil) 

end

function item:on_obtaining(variant, savegame_variable)

  -- Reset Acorn and Power fragment stats
  game:set_value("stats_acorn_count", 0)
  
end

function item:on_obtaining(variant, savegame_variable)

  -- Sound
  audio_manager:play_sound("items/get_power_up")

end