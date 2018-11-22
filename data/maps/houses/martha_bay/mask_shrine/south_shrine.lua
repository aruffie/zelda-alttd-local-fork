local map = ...
local game = map:get_game()

local light_manager = require("scripts/maps/light_manager")

-- Event called at initialization time, as soon as this map becomes is loaded.
function map:on_started()

  light_manager:init(map)
  map:set_doors_open("door_boss_1")
  --Boss
  if game:get_value("southern_shrine_boss") then 
    boss_sensor:set_enabled(false) 
    map:set_doors_open("door_boss_2")
  else boss:set_enabled(false) end

end

--BOSS ACTIVED
function boss_sensor:on_activated()
    hero:freeze()
    map:close_doors("door_boss")
    sol.audio.stop_music()
    sol.timer.start(1000,function()
      hero:unfreeze()
      boss:set_enabled(true)
      audio_manager:play_music("small_boss")
      boss_sensor:set_enabled(false)
    end)
end
--BOSS
if boss ~= nil then
 function boss:on_dead()
  audio_manager:play_sound("others/secret1") 
  audio_manager:play_music("southern_shrine")
  map:open_doors("door_boss") 
 end
end

-- Separator events
auto_separator_1:register_event("on_activated", function(separator, direction4)
    if direction4 == 1 then
      map:set_light(0)
    else
      map:set_light(1)
    end
end)