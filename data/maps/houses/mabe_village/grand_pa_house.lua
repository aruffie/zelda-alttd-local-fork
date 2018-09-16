-- Variables
local map = ...
local game = map:get_game()
local hero = map:get_hero()

-- Map events
function map:on_started(destination)

    map:init_music()
  
end

function grandpa:on_interaction()

      map:talk_to_grandpa()

end

-- Initialize the music of the map
function map:init_music()

  if game:get_value("main_quest_step") == 3  then
    sol.audio.play_music("maps/out/sword_search")
  else
    sol.audio.play_music("maps/houses/telephone_booth")
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

-- NPC events
function phone_interaction:on_interaction()

      map:talk_to_phone()

end

-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end
