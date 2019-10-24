-- Initialize Map behavior specific to this quest.

-- Variables
local map_meta = sol.main.get_metatable("map")

-- Include scripts
require ("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

map_meta:register_event("on_opening_transition_finished", function(map, destination)
    debug_print ("End of built-in transition")

    local game = map:get_game()
    local hero = map:get_hero()

    local ground=game:get_value("tp_ground")
    if ground=="hole" and not map:is_sideview() then
      hero:set_visible()
      hero:fall_from_ceiling(120, nil, function()
          hero:play_ground_effect()

        end)
    end-- Initialize Map behavior specific to this quest.

-- Variables
local map_meta = sol.main.get_metatable("map")

-- Include scripts
require ("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

map_meta:register_event("on_opening_transition_finished", function(map, destination)
    debug_print ("End of built-in transition")

    local game = map:get_game()
    local hero = map:get_hero()

    local ground=game:get_value("tp_ground")
    if ground=="hole" and not map:is_sideview() then
      hero:set_visible()
      hero:fall_from_ceiling(120, nil, function()
          hero:play_ground_effect()

        end)
    end

  end)

map_meta:register_event("on_started", function(map)
    debug_print("Start of the map")
    local game = map:get_game()
    local hero = map:get_hero()
    local ground=game:get_value("tp_ground")
    if ground=="hole" and not map:is_sideview() then
      hero:set_visible(false)
    else
      hero:set_visible()
    end
  end)