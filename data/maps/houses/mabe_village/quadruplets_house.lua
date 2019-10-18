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

end)

-- Initialize the music of the map
function map:init_music()

  if game:is_step_last("shield_obtained") then
    audio_manager:play_music("07_koholint_island")
  else
    audio_manager:play_music("12_house")
  end

end

-- Initializes entities based on player's progress
function map:init_map_entities()
 
  local item = game:get_item("magnifying_lens")
  local variant = item:get_variant()
  local father_sprite = father:get_sprite()
  if game:is_step_done("dungeon_3_completed") and variant < 8  then
    father:set_enabled(false)
  end
  if variant >= 8 then
    father_sprite:set_animation("calling")
  end

end

-- Discussion with Father
function map:talk_to_father() 

  local item = game:get_item("magnifying_lens")
  local variant = item:get_variant()
  local father_sprite = father:get_sprite()
  if variant >= 8 then
    game:start_dialog("maps.houses.mabe_village.quadruplets_house.father_2", function()
      father_sprite:set_direction(3)
    end)
  else
    game:start_dialog("maps.houses.mabe_village.quadruplets_house.father_1", function()
      father_sprite:set_direction(3)
    end)
  end

end

-- Discussion with Mother
function map:talk_to_mother() 

  local item = game:get_item("magnifying_lens")
  local variant = item:get_variant()
  if not game:is_step_done("dungeon_3_completed") then
    if variant == 1 then
      local symbol = mother:create_symbol_exclamation(true)
      game:start_dialog("maps.houses.mabe_village.quadruplets_house.mother_2", function(answer)
        if answer == 1 then
            game:start_dialog("maps.houses.mabe_village.quadruplets_house.mother_4", function()
              hero:start_treasure("magnifying_lens", 2, "magnifying_lens_2")
              mother:get_sprite():set_direction(3)
            end)
        else
          game:start_dialog("maps.houses.mabe_village.quadruplets_house.mother_3", function()
            mother:get_sprite():set_direction(3)
          end)
        end
        symbol:remove()
      end)
    elseif variant > 1 then
      game:start_dialog("maps.houses.mabe_village.quadruplets_house.mother_5", function()
        mother:get_sprite():set_direction(3)
      end)
    else
      game:start_dialog("maps.houses.mabe_village.quadruplets_house.mother_1", function()
        mother:get_sprite():set_direction(3)
      end)
    end
  else
    if variant >= 8 then
      game:start_dialog("maps.houses.mabe_village.quadruplets_house.mother_5", function()
        mother:get_sprite():set_direction(3)
      end)
    else
      game:start_dialog("maps.houses.mabe_village.quadruplets_house.mother_6", function()
        mother:get_sprite():set_direction(3)
      end)
    end
  end

end

-- NPCs events
function father:on_interaction()

  map:talk_to_father()

end

function mother:on_interaction()

  map:talk_to_mother()

end

-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end