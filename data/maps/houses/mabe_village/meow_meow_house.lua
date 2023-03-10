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

  if game:is_step_last("shield_obtained") then
    audio_manager:play_music("07_koholint_island")
  elseif game:is_step_last("dungeon_1_completed") or game:is_step_last("bowwow_dognapped") then
    audio_manager:play_music("26_bowwow_dognapped")
  else
    audio_manager:play_music("12_house")
  end

end

-- Initializes entities based on player's progress
function map:init_map_entities()
 
  if game:is_step_last("dungeon_1_completed") or game:is_step_last("bowwow_dognapped") then
    meow_meow:get_sprite():set_animation("panicked")
  end
  local item = game:get_item("magnifying_lens")
  if item:get_variant() > 2 then
    small_bowwow_2:get_sprite():set_animation("ruban")
  end
  map:repeat_meow_meow_direction_check()

end

-- Function that forces Mrs Meow Meow to always watch the hero
function map:repeat_meow_meow_direction_check()

  local direction4 = meow_meow:get_direction4_to(hero)
  meow_meow:get_sprite():set_direction(direction4)
  sol.timer.start(map, 100, function() 
    map:repeat_meow_meow_direction_check()
  end)

end

-- Discussion with Mrs Meow Meow
function map:talk_to_meow_meow() 

  if not game:is_step_done("dungeon_1_completed") then
    game:start_dialog("maps.houses.mabe_village.meow_meow_house.meow_meow_1")
  elseif game:is_step_last("dungeon_1_completed") or game:is_step_last("bowwow_dognapped") then
    game:start_dialog("maps.houses.mabe_village.meow_meow_house.meow_meow_2")
  elseif game:is_step_last("bowwow_joined") then
    game:start_dialog("maps.houses.mabe_village.meow_meow_house.meow_meow_3")
  elseif game:is_step_last("dungeon_2_completed") then
    game:start_dialog("maps.houses.mabe_village.meow_meow_house.meow_meow_4", function()
      game:set_step_done("bowwow_returned")
    end)
  else
    game:start_dialog("maps.houses.mabe_village.meow_meow_house.meow_meow_1")
  end

end

-- Discussion with Small bowwow 1
function map:talk_to_small_bowwow_1() 

  audio_manager:play_sound("misc/bowwow")
  game:start_dialog("maps.houses.mabe_village.meow_meow_house.small_bowwow_1_1")

end

-- Discussion with Small bowwow 2
function map:talk_to_small_bowwow_2() 

  audio_manager:play_sound("misc/bowwow")
  local item = game:get_item("magnifying_lens")
  local variant = item:get_variant()
  if variant == 2 then
    local symbol = small_bowwow_2:create_symbol_exclamation(true)
    game:start_dialog("maps.houses.mabe_village.meow_meow_house.small_bowwow_2_2", function(answer)
      if answer == 1 then
        audio_manager:play_sound("misc/bowwow")
        game:start_dialog("maps.houses.mabe_village.meow_meow_house.small_bowwow_2_4", function()
          small_bowwow_2:get_sprite():set_animation("ruban")
          hero:start_treasure("magnifying_lens", 3, "magnifying_lens_3")
        end)
      else
        game:start_dialog("maps.houses.mabe_village.meow_meow_house.small_bowwow_2_3")
      end
      symbol:remove()
    end)
  elseif variant > 1 then
    game:start_dialog("maps.houses.mabe_village.meow_meow_house.small_bowwow_2_1")
  else
    game:start_dialog("maps.houses.mabe_village.meow_meow_house.small_bowwow_2_1")
  end

end

-- NPCs events
function meow_meow:on_interaction()

  map:talk_to_meow_meow()

end

function small_bowwow_1:on_interaction()

  map:talk_to_small_bowwow_1()

end

function small_bowwow_2:on_interaction()

  map:talk_to_small_bowwow_2()

end

-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end