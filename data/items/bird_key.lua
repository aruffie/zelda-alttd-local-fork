-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function item:on_created()

  item:set_savegame_variable("possession_bird_key")
  item:set_sound_when_brandished(nil)

end

function item:on_obtaining()
  
  -- Sound
  audio_manager:play_sound("items/fanfare_item_extended")
        
end