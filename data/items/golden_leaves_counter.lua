-- Lua script of item "golden leaves counter".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Event called when the game is initialized.
function item:on_created()

  self:set_savegame_variable("possession_golden_leafs_counter")
  self:set_amount_savegame_variable("amount_golden_leafs_counter")
  self:set_assignable(false)
  self:set_sound_when_brandished(nil)
  self:set_max_amount(5)

end

function item:on_obtaining()
  
  -- Sound
  audio_manager:play_sound("items/fanfare_item_extended")
        
end
