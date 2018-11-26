-- Initialize block behavior specific to this quest.

-- Variables
local explosion_meta = sol.main.get_metatable("explosion")

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function explosion_meta:on_created()
    
  audio_manager:play_sound("items/bomb_explode")
  
end