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
  
end

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("12_house")

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
 
  -- Ananas
  if game:get_value("main_quest_step") > 20 then
    ananas:set_enabled(false)
  end

end

-- Discussion with Bear
function map:talk_to_bear()

  local direction4 = bear:get_direction4_to(hero)
  local bear_sprite = bear:get_sprite()
  bear_sprite:set_direction(direction4)
  bear_sprite:set_animation("stopped")
  if game:get_value("main_quest_step") < 20 then
    game:start_dialog("maps.houses.yarna_desert.bear_house.bear_1", function()
      bear_sprite:set_direction(3)
      bear_sprite:set_animation("waiting")
    end)
  elseif game:get_value("main_quest_step") == 20  then
    game:start_dialog("maps.houses.yarna_desert.bear_house.bear_2", function(answer)
      if answer == 1 then
        ananas:set_enabled(false)
        hero:start_treasure("magnifying_lens", 7, "magnifying_lens_6", function()
          game:start_dialog("maps.houses.yarna_desert.bear_house.bear_4", function()
            bear_sprite:set_direction(3)
            bear_sprite:set_animation("waiting")
          end)
        end)
      else
        game:start_dialog("maps.houses.yarna_desert.bear_house.bear_3", function()
          bear_sprite:set_direction(3)
          bear_sprite:set_animation("waiting")
        end)
      end
    end)
  else
    game:start_dialog("maps.houses.yarna_desert.bear_house.bear_4", function()
      bear_sprite:set_direction(3)
      bear_sprite:set_animation("waiting")
    end)
  end

end

-- NPCs events
function bear:on_interaction()

  map:talk_to_bear()

end

function bear_invisible:on_interaction()

  map:talk_to_bear()

end

-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end
