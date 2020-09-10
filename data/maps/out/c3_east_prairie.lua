-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  -- Digging
  map:set_digging_allowed(true)

end)

-- Initialize the music of the map
function map:init_music()
  
  audio_manager:play_music("10_overworld")

end

-- Activate beetle spawn if hero near enough the spawner.
sol.timer.start(map, 50, function()

  local distance = hero:get_distance(spawner_beetle_1)
  if not spawner_beetle_1:is_active() and distance <= 32 then
    spawner_beetle_1:start()
  end
  if spawner_beetle_1:is_active() and distance > 32 then
    spawner_beetle_1:stop()
  end

  return true
end)