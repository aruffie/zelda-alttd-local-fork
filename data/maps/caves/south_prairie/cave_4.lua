-- Variables
local map = ...
local game = map:get_game()

-- Includes scripts
local separator_manager = require("scripts/maps/separator_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events
function map:on_started(destination)

  -- Music
  map:init_music()
  
end

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("18_cave")

end

-- Map events
function map:on_started()

  --Invisible things: only visible with the Lens
  if game:get_value("get_lens") then
    map:set_entities_enabled("trader",true)
  else
    map:set_entities_enabled("trader",false)
  end

end

-- Traders
for trader in map:get_entities("trader") do
  function trader:on_interaction()
    local dialog
    if game:get_value("get_boomerang") then dialog = "maps.houses.south_prairie.boomerang_cave.recover_item_before_question" else dialog = "maps.houses.south_prairie.boomerang_cave.boomerang_question" end
    game:start_dialog(dialog, function(answer)
        if answer == 1 then
          if game:get_value("get_boomerang") then
            game:set_value("get_boomerang",false)
            hero:start_treasure("shovel",1)
            if game:get_item_assigned(1) == game:get_item("boomerang") then game:set_item_assigned(1, game:get_item("shovel")) end
            if game:get_item_assigned(2) == game:get_item("boomerang") then game:set_item_assigned(2, game:get_item("shovel")) end
          else
            hero:start_treasure("boomerang",1,"get_boomerang")
            if game:get_item_assigned(1) == game:get_item("shovel") then game:set_item_assigned(1, game:get_item("boomerang")) end
            if game:get_item_assigned(2) == game:get_item("shovel") then game:set_item_assigned(2, game:get_item("boomerang")) end
          end
        else
          game:start_dialog("maps.houses.south_prairie.boomerang_cave.no", game:get_player_name())
        end
    end)
  end
end

separator_manager:manage_map(map)