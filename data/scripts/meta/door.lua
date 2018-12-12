-- Initialize door behavior specific to this quest.

-- Variables
local door_meta = sol.main.get_metatable("door")

-- Include scripts
local audio_manager = require("scripts/audio_manager")
require("scripts/multi_events")

door_meta:register_event("on_opened", function(door)
  
  local sprite = door:get_sprite()
  if sprite:get_animation() == "opening" then
    audio_manager:play_sound("others/dungeon_door_open")
  end
      
end)

door_meta:register_event("on_closed", function(door)

  local sprite = door:get_sprite()
  if sprite:get_animation() == "closing" then
    audio_manager:play_sound("others/dungeon_door_slam")
  end

end)