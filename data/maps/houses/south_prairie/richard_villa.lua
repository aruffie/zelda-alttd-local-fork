-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

map:register_event("on_started", function(map, destination)
  
  -- Music
  map:init_music()
  -- Entities
  map:init_map_entities()

end)

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("30_richard_villa")

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
 
  if game:get_value("richard_box_moved") then
    local x,y,layer = box_place:get_position()
    box:set_position(x,y,layer)
  end
  if game:is_step_done("golden_leaved_returned") then
    local x,y,layer = richard_place:get_position()
    richard:set_position(x,y,layer)
  end

end

-- Discussion with Richard
function map:talk_to_richard() 

  if not game:is_step_done("bowwow_returned") then
    game:start_dialog("maps.houses.south_prairie.richard_villa.richard_1")
  elseif game:is_step_done("golden_leaved_returned") then
    game:start_dialog("maps.houses.south_prairie.richard_villa.richard_8")
  else
    local item = game:get_item("golden_leaves_counter")
    local num = item:get_amount()
    if num == nil or num == 0 then
      game:start_dialog("maps.houses.south_prairie.richard_villa.richard_2", function(answer)
          if answer == 1 then
            game:start_dialog("maps.houses.south_prairie.richard_villa.richard_4")
          else
            game:start_dialog("maps.houses.south_prairie.richard_villa.richard_3")
          end
      end)
    else 
      if num == 5 then
        game:start_dialog("maps.houses.south_prairie.richard_villa.richard_7", function()
          game:set_step_done("golden_leaved_returned")
          item:set_amount(0)
          local movement = sol.movement.create("target")
          movement:set_speed(30)
          movement:set_target(richard_place)
          movement:start(richard)
          function movement:on_finished()
            richard:get_sprite():set_direction(3)
          end
        end)
      else
        game:start_dialog("maps.houses.south_prairie.richard_villa.richard_6", game:get_player_name())
      end
    end
  end

end

-- Blocks events
function box:on_moved()

  game:set_value("richard_box_moved", true) 

end

-- NPCs events
function richard:on_interaction()

  map:talk_to_richard()

end

for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end
