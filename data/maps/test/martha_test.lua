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
  -- Entities
  map:init_map_entities()
  -- Digging
  map:set_digging_allowed(true)

end)

-- Initialize the music of the map
function map:init_music()
  
  audio_manager:play_music("10_overworld")

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
  
  --Mermaid statue pushed
  if game:get_value("mermaid_statue_pushed") then
      mermaid_statue_npc:set_enabled(false)
      mermaid_statue_1:set_position(416,373)
      mermaid_statue_2:set_position(416,344)
  end
  
end

-- NPCs events
function mermaid_statue_npc:on_interaction()

  if game:get_item("magnifying_lens"):get_variant() == 13 then
    audio_manager:play_sound("chest_open")
    game:start_dialog("maps.out.martha_bay.mermaid_statue_scale",function()
      hero:freeze()
      mermaid_statue_npc:set_enabled(false)
      audio_manager:play_sound("hero_pushes")
        local mermaid_statue_1_x,mermaid_statue_1_y = mermaid_statue_1:get_position()
        local mermaid_statue_2_x,mermaid_statue_2_y = mermaid_statue_2:get_position()
        local i = 0
        sol.timer.start(map, 50, function()
          i = i + 1
          mermaid_statue_1_x = mermaid_statue_1_x - 1
          mermaid_statue_2_x = mermaid_statue_2_x - 1
          mermaid_statue_1:set_position(mermaid_statue_1_x, mermaid_statue_1_y)
          mermaid_statue_2:set_position(mermaid_statue_2_x, mermaid_statue_2_y)
          if i < 32 then
            return true
          end
          audio_manager:play_sound("misc/secret1")
          hero:unfreeze()
          game:set_value("mermaid_statue_pushed",true)
        end)
    end)
  else 
    game:start_dialog("maps.out.martha_bay.mermaid_statue_no_scale")
  end

end

-- Underwater teleporters.
local function underwater_teleport(map, destination)

  -- Teleport only if the hero is diving.
  local custom_state = hero:get_state_object()
  if custom_state and custom_state:get_description() == "diving" then
    hero:teleport(map, destination, "fade")
  end
end

function sideview_1_1_A:on_activated_repeat() -- Use the on_activated_repeat() event to take care of state changing to swimming while not moving.

  underwater_teleport("sideviews/martha_bay/sideview_1", "sideview_1_1_B")
end

function sideview_2_1_A:on_activated_repeat()

  underwater_teleport("sideviews/martha_bay/sideview_2", "sideview_2_1_B")
end

function sideview_2_2_A:on_activated_repeat()

  underwater_teleport("sideviews/martha_bay/sideview_2", "sideview_2_2_B")
end