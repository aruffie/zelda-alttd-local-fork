-- Variables
local map = ...
local game = map:get_game()
local music_name = sol.audio.get_music()

-- Include scripts
local light_manager = require("scripts/maps/light_manager")

-- Map events.
function map:on_started()

  light_manager:init(map)
  map:set_light(0)

end

-- Discussion with Witch
function map:talk_to_witch() 

  local item1 = game:get_item_assigned(1)
  local item2 = game:get_item_assigned(2)
  local name1 = false
  local name2 = false
  if item1~= nil then
    name1 = item1:get_name() 
  end
  if item2~= nil then
    name2 = item2:get_name() 
  end
  if game:has_item("mushroom") and (name1 == "mushroom" or name2 == "mushroom") then
    local slot = 1
    if name2 == "mushroom" then
      slot = 2
    end
    game:start_dialog("maps.houses.graveyard.witch_house.witch_2", function() 
      map:launch_cinematic_1(slot)
    end)
  else
    game:start_dialog("maps.houses.graveyard.witch_house.witch_1")
  end

end

-- Cinematics 
-- This is the cinematic when the witch makes magic powder
function map:launch_cinematic_1(slot)
    
  -- Init and launch cinematic mode
  local options = {
    entities_ignore_suspend = {witch, mouse}
  }
  map:set_cinematic_mode(true, options)
  local mushroom = game:get_item("mushroom")
  mushroom:set_variant(0)
  sol.audio.play_music("maps/houses/shop_high")
  witch:get_sprite():set_animation("speeding")
  sol.timer.start(4000, function()
    witch:get_sprite():set_animation("walking")
    sol.audio.play_music(music_name)
    game:set_hud_enabled(true)
    game:start_dialog("maps.houses.graveyard.witch_house.witch_3", function() 
      hero:start_treasure("magic_powders_counter", 1, nil, function()
        map:set_cinematic_mode(false, options)
      end)
      local item = game:get_item("magic_powders_counter")
      game:set_item_assigned(slot, item)
    end)
  end)

end

-- NPC events
function witch:on_interaction()

      map:talk_to_witch()

end

-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end
