-- Lua script of item "slim key".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Event called when the game is initialized.
function item:on_created()

  item:set_savegame_variable("possession_slim_key")
  item:set_sound_when_brandished(nil)

end

function item:on_obtaining()
  
  self:get_game():set_value("main_quest_step", 16) -- Todo remove and place it in map
  audio_manager:play_sound("items/fanfare_item_extended")
        
end