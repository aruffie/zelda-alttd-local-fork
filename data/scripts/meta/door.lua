-- Initialize door behavior specific to this quest.

-- Variables
local door_meta = sol.main.get_metatable("door")

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function door_meta:on_opened()
  
  local sprite = self:get_sprite()
  if sprite:get_animation() == "opening" then
    audio_manager:play_sound("others/dungeon_door_open")
  end
      
end

function door_meta:on_closed()
  
  local sprite = self:get_sprite()
  if sprite:get_animation() == "closing" then
    audio_manager:play_sound("others/dungeon_door_slam")
  end
      
end