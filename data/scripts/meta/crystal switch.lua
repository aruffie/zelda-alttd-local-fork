local crystal_switch_meta=sol.main.get_metatable("crystal_switch")
require "scripts/multi_events"
local audio_manager=require "scripts/audio_manager"

crystal_switch_meta:register_event("on_activated", function(switch)
  audio_manager:play_sound("misc/dungeon_crystal")
end)