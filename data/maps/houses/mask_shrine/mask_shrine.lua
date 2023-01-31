local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local light_manager = require("scripts/maps/light_manager")
local door_manager = require("scripts/maps/door_manager")
local audio_manager = require("scripts/audio_manager")

-- Event called at initialization time, as soon as this map becomes is loaded.
map:register_event("on_started", function(map, destination)

  light_manager:init(map)
  audio_manager:play_music("58_southern_shrine")

  -- Doors
  map:set_doors_open("door_boss_")

  -- Boss
  if game:get_value("armos_knight_killed") then 
    armos_knight:remove()
  else
    door_manager:open_when_enemies_dead(map, "armos_knight", "door_boss_")
    armos_knight:register_event("on_dead", function(armos_knight)
      sol.audio.stop_music()
      audio_manager:play_music("58_southern_shrine")
    end)
  end

end)

-- Sensors events
function boss_sensor:on_activated()

  if game:get_value("armos_knight_killed") then
    return
  end

  boss_sensor:set_enabled(false)
  map:close_doors("door_boss_")
  sol.audio.stop_music()
  audio_manager:play_music("21_mini_boss_battle")
end