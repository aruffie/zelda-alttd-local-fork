-- Initialize Map behavior specific to this quest.

-- Variables
local map_meta = sol.main.get_metatable("map")

-- Include scripts
require ("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

map_meta:register_event("on_opening_transition_finished", function(map, destination)

  local game = map:get_game()
  local hero = map:get_hero()
  local ground=game:get_value("tp_ground")
  if ground=="hole" and not map:is_sideview() then
    hero:fall_from_ceiling(120, nil, function()
      local ground=hero:get_ground_below()
      if ground=="shallow_water" then
        audio_manager:play_sound("hero/wade1")
      elseif ground=="grass" then
        audio_manager:play_sound("walk_on_grass") --TODO use the actual sound effect
      elseif ground=="deep_water" then
        audio_manager:play_sound("hero/diving")
      else
        audio_manager:play_sound("hero/land")
      end
    end)
  end
 
end)