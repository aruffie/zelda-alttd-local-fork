-- Variables
local map = ...
local game = map:get_game()
local hero_has_already_talk = false

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Map events
function map:on_started(destination)

  -- Music
  map:init_music()
  
end

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("14_shop")

end

-- Discussion with Monique
function map:talk_to_crazy_tracy()
  
  local item = game:get_item("drug")
  local variant = item:get_variant()
  local drug_already_buy = game:get_value("drug_already_buy")
  local drug_buy_occurence = game:get_value("drug_buy_occurence")
  if drug_buy_occurence == nil then
    drug_buy_occurence = 0
  end
  local amount = 28
  if drug_already_buy and math.random(2) == 1 then
    amount = 42
  end
  print(drug_buy_occurence)
  if not hero_has_already_talk then
    game:start_dialog("maps.houses.graveyard.drugstore.crazy_tracy_1", function()
      hero_has_already_talk = true
    end)
  else
    if variant > 0 then
      game:start_dialog("maps.houses.graveyard.drugstore.crazy_tracy_4")
    else
      game:start_dialog("maps.houses.graveyard.drugstore.crazy_tracy_2",amount, function(answer)
        if answer == 1 then
          local money = game:get_money()
          if money >= amount then
            if drug_buy_occurence == 7 then
              amount = 7
              game:start_dialog("maps.houses.graveyard.drugstore.crazy_tracy_7", function()
                 map:launch_transaction_with_crazy_tracy(amount)
              end)
            else
                map:launch_transaction_with_crazy_tracy(amount)
            end
          else
            game:start_dialog("maps.houses.graveyard.drugstore.crazy_tracy_3")
          end
        else
          game:start_dialog("maps.houses.graveyard.drugstore.crazy_tracy_5")
        end
        hero_has_already_talk = false
      end)
    end
  end

end

-- Transaction with Crazy Tracy
function map:launch_transaction_with_crazy_tracy(amount)
  local item = game:get_item("drug")
  local variant = item:get_variant()
  local drug_buy_occurence = game:get_value("drug_buy_occurence")
  local x_hero,y_hero, layer_hero = hero:get_position()
  if drug_buy_occurence == nil then
    drug_buy_occurence = 0
  end
  hero:set_animation("brandish")  
  local drug_entity = map:create_custom_entity({
    name = "brandish_drug",
    sprite = "entities/items",
    x = x_hero,
    y = y_hero - 24,
    width = 16,
    height = 16,
    layer = 1,
    direction = 0
  })
  drug_entity:get_sprite():set_animation("drug")
  drug_entity:get_sprite():set_direction(0)
  audio_manager:play_sound("items/fanfare_item")
  game:remove_money(amount)
  game:start_dialog("maps.houses.graveyard.drugstore.crazy_tracy_6", function()
    item:set_variant(1)
    drug_buy_occurence = drug_buy_occurence + 1
    game:set_value("drug_buy_occurence", drug_buy_occurence)
    game:set_value("drug_already_buy", true)
    hero:set_animation("stopped")
    map:remove_entities("brandish")
    hero:unfreeze()
    -- Life
    if game:get_life() < game:get_max_life() then
        game:start_dialog("maps.houses.graveyard.drugstore.crazy_tracy_8", function()
            game:set_life(game:get_max_life())
        end)
    end
  end)
end

-- NPCs events

function crazy_tracy:on_interaction()

  map:talk_to_crazy_tracy()

end

-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end
