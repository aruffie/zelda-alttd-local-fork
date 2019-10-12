-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")
local separator_manager = require("scripts/maps/separator_manager")

-- Map events

map:register_event("on_started", function()
    
  -- Music
  game:play_dungeon_music()
  -- Separators
  separator_manager:init(map)
  
end)

