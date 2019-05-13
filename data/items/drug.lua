-- Lua script of item "drug".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Event called when the game is initialized.
function item:on_created()

  item:set_savegame_variable("possession_drug")

end

function item:on_obtaining()
  
  audio_manager:play_sound("items/fanfare_item")
        
end

