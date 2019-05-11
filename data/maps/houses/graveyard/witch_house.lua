-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local light_manager = require("scripts/maps/light_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events.
function map:on_started()

  -- Music
  map:init_music()
  -- Light
  light_manager:init(map)
  map:set_light(0)

end

-- Initialize the music of the map
function map:init_music()
  
  audio_manager:play_music("14_shop")

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

-- NPCs events
function witch:on_interaction()
  
  map:talk_to_witch() 

end

-- Torches events
timed_torch_1:register_event("on_lit", function()

    if not game:get_value("witch_indication") then
      game:set_value("witch_indication", true)
      game:start_dialog("maps.houses.graveyard.witch_house.witch_4")
    end
    
end)


-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end

-- Cinematics 
-- This is the cinematic when the witch makes magic powder
function map:launch_cinematic_1(slot)
    
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {witch, mouse}
    }
    map:set_cinematic_mode(true, options)
    local mushroom = game:get_item("mushroom")
    mushroom:set_variant(0)
    audio_manager:play_music("14_shop_high")
    witch:get_sprite():set_animation("speeding")
    wait(4000)
    witch:get_sprite():set_animation("walking")
    audio_manager:play_music("14_shop")
    game:set_hud_enabled(true)
    game:start_dialog("maps.houses.graveyard.witch_house.witch_3", function() 
      hero:start_treasure("magic_powders_counter", 1, nil, function()
        game:set_value("witch_indication", false)
        map:set_cinematic_mode(false, options)
      end)
      local item = game:get_item("magic_powders_counter")
      game:set_item_assigned(slot, item)
    end)
  end)

end
