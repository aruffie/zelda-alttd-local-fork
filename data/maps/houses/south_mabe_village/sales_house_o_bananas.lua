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

end)

-- Initialize the music of the map
function map:init_music()

  if game:get_value("main_quest_step") == 3  then
    audio_manager:play_music("07_koholint_island")
  else
    audio_manager:play_music("12_house")
  end

end

-- Discussion with Alligator
function map:talk_to_alligator() 

  local item = game:get_item("magnifying_lens")
  local variant = item:get_variant()
  local sprite = alligator:get_sprite()
  if variant == 3 then
    game:start_dialog("maps.houses.south_mabe_village.sales_house_o_bananas.alligator_2", function(answer)
      if answer == 1 then
        game:start_dialog("maps.houses.south_mabe_village.sales_house_o_bananas.alligator_4", function()
          map:launch_cinematic_1()
        end)
      else
        game:start_dialog("maps.houses.south_mabe_village.sales_house_o_bananas.alligator_3")
      end
    end)
  elseif variant > 3 then
    game:start_dialog("maps.houses.south_mabe_village.sales_house_o_bananas.alligator_6")
  else
    game:start_dialog("maps.houses.south_mabe_village.sales_house_o_bananas.alligator_1")
  end
end

-- NPCs events
function alligator:on_interaction()

  map:talk_to_alligator()

end

-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end

-- Cinematics
-- This is the cinematic that the alligator eat dog food.
function map:launch_cinematic_1()
  
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, alligator}
    }
   map:set_cinematic_mode(true, options)
    -- The hero moves away from the alligator
    hero:set_direction(2)
    hero:set_animation("walking")
    local m1 = sol.movement.create("path")
    m1:set_path{4,4,4,4}
    m1:set_ignore_suspend(true)
    m1:set_speed(80)
    movement(m1, hero)
    hero:set_animation("stopped")
    wait(1000)
    hero:set_direction(0)
    wait(2000)
    -- Create food entity
    local x_hero,y_hero, layer_hero = hero:get_position()
    local food = map:create_custom_entity({
      name = "food",
      sprite = "entities/items",
      x = x_hero,
      y = y_hero - 8,
      width = 16,
      height = 16,
      layer = 1,
      direction = 0
    })
    food:get_sprite():set_animation("magnifying_lens")
    food:get_sprite():set_direction(2)
    audio_manager:play_sound("hero/jump")
    alligator:get_sprite():set_animation("begin_eating")
    -- The hero throws the food
    local m2 = sol.movement.create("jump")
    m2:set_direction8(0)
    m2:set_distance(56)
    m2:set_speed(120)
    m2:set_ignore_suspend(true)
    movement(m2, food)
    alligator:get_sprite():set_animation("eating")
    food:remove()
    wait(2000)
    -- The hero returns to his initial position
    hero:set_animation("walking")
    local m3 = sol.movement.create("path")
    m3:set_path{0,0,0,0}
    m3:set_speed(80)
    m3:set_ignore_suspend(true)
    movement(m3, hero)
    alligator:get_sprite():set_animation("waiting")
    hero:set_animation("stopped")
    map:set_cinematic_mode(false, options)
    -- Alligator gives treasure
    dialog("maps.houses.south_mabe_village.sales_house_o_bananas.alligator_5")
    hero:start_treasure("magnifying_lens", 4, "magnifying_lens_4")
  end)

end