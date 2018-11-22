-- Initialize switch behavior specific to this quest.

-- Variables
local door_meta = sol.main.get_metatable("door")

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function door_meta:on_closed()
    
  audio_manager:play_sound("others/dungeon_door_slam")
      
end