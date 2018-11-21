-- Initialize chest behavior specific to this quest.

-- Variables
local chest_meta = sol.main.get_metatable("chest")

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function chest_meta:on_opened()
  
  audio_manager:play_sound("others/chest_open")
  
end