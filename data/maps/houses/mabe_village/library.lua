-- Variables
local map = ...
local game = map:get_game()
local hero = map:get_hero()

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

  if game:get_value("main_quest_step") == 3  then
    audio_manager:play_music("07_koholint_island")
  else
    audio_manager:play_music("12_house")
  end

end

-- Initializes Entities based on player's progress
function map:init_map_entities()

    -- Secret book
  book_9:set_enabled(false)
  if game:get_value("get_secret_book") then
    book_9:set_enabled(true)
    book_secret:set_enabled(false)
  end
  collision_book:add_collision_test("facing", function(entity, other, entity_sprite, other_sprite)
    if other:get_type() == 'hero' and hero:get_state() == "custom" and hero:get_state_object():get_description()=="running"  and game:get_value("get_secret_book") == nil then
      sol.timer.start(map, 250, function()
        movement = sol.movement.create("jump")
        movement:set_speed(100)
        movement:set_distance(32)
        movement:set_direction8(6)
        movement:set_ignore_obstacles(true)
        movement:start(book_secret, function()
          audio_manager:play_sound("jump")
          game:set_value("get_secret_book", true)
          book_9:set_enabled(true)
          book_secret:set_enabled(false)
        end)
      end)
    end
  end)

end

-- Discussion with Book
function map:open_book(book)

  game:start_dialog("maps.houses.mabe_village.library.book_"..book..".question", function(answer)
    if answer == 1 then
      local entity = map:get_entity("book_"..book)
      local sprite = entity:get_sprite()
      sprite:set_animation("reading")
      if book == 8 then
        if game:get_value("get_lens") then
          game:start_dialog("maps.houses.mabe_village.library.book_"..book..".true_content", function()
            sprite:set_animation("normal")
          end)
        else
          game:start_dialog("maps.houses.mabe_village.library.book_"..book..".content", function()
            sprite:set_animation("normal")
          end)
        end
      elseif book ~= 7 then
        game:start_dialog("maps.houses.mabe_village.library.book_"..book..".content", function()
          sprite:set_animation("normal")
        end)
      end
    end
  end)

end

-- NPCs events
function book_1_interaction:on_interaction()

  map:open_book(1)

end

function book_2_interaction:on_interaction()

  map:open_book(2)

end

function book_3_interaction:on_interaction()

  map:open_book(3)

end

function book_4_interaction:on_interaction()

  map:open_book(4)

end

function book_5_interaction:on_interaction()

  map:open_book(5)

end

function book_6_interaction:on_interaction()

  map:open_book(6)

end

function book_7_interaction:on_interaction()

  map:open_book(7)

end

function book_8_interaction:on_interaction()

  map:open_book(8)

end

function book_9:on_interaction()

  map:open_book(9)

end

-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_2", game:get_player_name())
  end
end

