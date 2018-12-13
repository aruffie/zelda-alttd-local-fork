-- Initialize switch behavior specific to this quest.

-- Variables
local switch_meta = sol.main.get_metatable("switch")

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function switch_meta:on_activated()
    
  audio_manager:play_sound("misc/dungeon_switch")
      
end