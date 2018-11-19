-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Map events
function map:on_started()

  -- Music
  map:init_music()
  -- Entities
  map:init_map_entities()
  -- Digging
  map:set_digging_allowed(true)

end

-- Initialize the music of the map
function map:init_music()
  
  audio_manager:play_music("10_overworld")

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
  
  --Mermaid statue pushed
  if game:get_value("mermaid_statue_pushed") then
      mermaid_statue_npc:set_enabled(false)
      mermaid_statue:set_position(424,373)
  end
  
end

-- NPCs events
function mermaid_statue_npc:on_interaction()

  if game:get_item("magnifying_lens"):get_variant() == 13 then
    sol.audio.play_sound("chest_open")
    game:start_dialog("maps.out.martha_bay.mermaid_statue_scale",function()
      hero:freeze()
      mermaid_statue_npc:set_enabled(false)
      sol.audio.play_sound("hero_pushes")
        local mermaid_statue_x,mermaid_statue_y = map:get_entity("mermaid_statue"):get_position()
        local i = 0
        sol.timer.start(map, 50, function()
          i = i + 1
          mermaid_statue_x = mermaid_statue_x - 1
          mermaid_statue:set_position(mermaid_statue_x, mermaid_statue_y)
          if i < 32 then
            return true
          end
          sol.audio.play_sound("secret_1")
          hero:unfreeze()
          game:set_value("mermaid_statue_pushed",true)
        end)
    end)
  else 
    game:start_dialog("maps.out.martha_bay.mermaid_statue_no_scale")
  end

end