-- Variables
local map = ...
local game = map:get_game()
local is_boss_active = false

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")
local separator_manager = require("scripts/maps/separator_manager")
local enemy_manager = require("scripts/maps/enemy_manager")

-- Starts the boss.
local function start_boss()
  
  if is_boss_active == false then
    is_boss_active = true
    enemy_manager:launch_boss_if_not_dead(map)

    boss:register_event("on_dying", function(boss)
      game:start_dialog("maps.dungeons.11.boss_dying")
    end)
  end
end

-- Map events
map:register_event("on_started", function()
    
  -- Music
  map:init_music()
  -- Separators
  separator_manager:init(map)
end)

-- Start boss.
map:register_event("on_opening_transition_finished", function(map, destination)

  start_boss()
end)

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("74_wind_fish_egg")

end

