-- Lua script of item "console".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Event called when the game is initialized.
function item:on_created()

  item:set_savegame_variable("possession_console")
  item:set_sound_when_brandished(nil)

end

function item:on_obtaining()
  
  -- Sound
  audio_manager:play_sound("items/fanfare_item_extended")
        
end