-- Lua script of item "tail key".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Event called when the game is initialized.
function item:on_created()

  item:set_savegame_variable("possession_tail_key")
  item:set_sound_when_brandished(nil)

end

function item:on_obtaining()
  
  audio_manager:play_sound("items/fanfare_item_extended")
        
end