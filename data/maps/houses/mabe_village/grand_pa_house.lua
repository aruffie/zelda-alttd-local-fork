-- Variables
local map = ...
local game = map:get_game()
local hero = map:get_hero()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

-- Map events
map:register_event("on_started", function(map, destination)

  map:init_music()
  
end)

-- Initialize the music of the map
function map:init_music()

  if game:is_step_last("shield_obtained") then
    audio_manager:play_music("07_koholint_island")
  else
    audio_manager:play_music("13_phone")
  end

end

-- Discussion with Grandpa
function map:talk_to_grandpa() 

  game:start_dialog("maps.houses.mabe_village.grandpa_house.grandpa_1")

end

-- Discussion with Phone
function map:talk_to_phone() 

  local phone = map:get_entity("phone")
  local phone_sprite = phone:get_sprite()
  phone_sprite:set_animation("calling")
  hero:freeze()
  hero:get_sprite():set_ignore_suspend(true)
  hero:set_animation("pickup_phone", function()
    hero:set_animation("calling")
    game:start_dialog("maps.houses.phone_booth.0", function() 
      hero:set_animation("hangup_phone", function()
        hero:unfreeze()
        phone_sprite:set_animation("stopped")
        hero:get_sprite():set_ignore_suspend(false)
      end)
    end)
  end)

end

-- NPCs events
function phone_interaction:on_interaction()

  map:talk_to_phone()

end

function grandpa:on_interaction()

  map:talk_to_grandpa()

end

-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end
