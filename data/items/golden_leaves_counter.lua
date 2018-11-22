local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function item:on_created()

  self:set_savegame_variable("possession_golden_leafs_counter")
  self:set_amount_savegame_variable("amount_golden_leafs_counter")
  self:set_assignable(false)
  self:set_sound_when_brandished(nil)

end

function item:on_obtaining()
  
  -- Sound
  audio_manager:play_sound("items/fanfare_item_extended")
        
end
