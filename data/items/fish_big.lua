local item = ...
local game = item:get_game()

local audio_manager = require("scripts/audio_manager")

function item:on_obtaining()
  
  audio_manager:play_sound("items/fanfare_item_extended")
        
end
