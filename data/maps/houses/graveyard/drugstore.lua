-- Variables
local map = ...
local game = map:get_game()
local hero=map:get_hero()
local intro_dialog_done = false

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

  audio_manager:play_music("14_shop")

end

-- Discussion with Monique
function crazy_tracy:on_interaction()
  
  local item = game:get_item("drug")
  local variant = item:get_variant()
  local drug_already_bought = game:get_value("drug_already_buy")
  local drugs_bought = game:get_value("drug_buy_occurence")
  if drugs_bought == nil then
    drugs_bought = 0
  end
  local amount = 28
  local killed_enemies=game.shop_drug_count or 0
  --if drug_already_bought and game.sell_drug_at_high_price then
  if drug_already_bought and killed_enemies%2 == 1 then
    amount = 42
  end
  if not intro_dialog_done then
    game:start_dialog("maps.houses.graveyard.drugstore.crazy_tracy_1", function()
      intro_dialog_done = true
    end)
  else
    if variant > 0 then --we already have one
      game:start_dialog("maps.houses.graveyard.drugstore.crazy_tracy_4")
    else --Try to sell one
      game:start_dialog("maps.houses.graveyard.drugstore.crazy_tracy_2",amount, function(answer)
        if answer == 1 then --Buy
          local money = game:get_money()
          if money >= amount then
            if drugs_bought == 7 then --Price discount
              amount = 7
              game:start_dialog("maps.houses.graveyard.drugstore.crazy_tracy_7", function()
                 map:launch_transaction_with_crazy_tracy(amount)
              end)
            else
                game:set_value("stats_shop_drug_count", killed_enemies%2)
                map:launch_transaction_with_crazy_tracy(amount)
            end
          else --Not enough money
            game:start_dialog("maps.houses.graveyard.drugstore.crazy_tracy_3")
          end
        else --don't buy
          game:start_dialog("maps.houses.graveyard.drugstore.crazy_tracy_5")
        end
        intro_dialog_done = false
      end)
    end
  end

end

-- Transaction with Crazy Tracy
function map:launch_transaction_with_crazy_tracy(amount)
  local item = game:get_item("drug")
  local variant = item:get_variant()
  local drugs_bought = game:get_value("drug_buy_occurence")
  local x_hero,y_hero, layer_hero = hero:get_position()
  if drugs_bought == nil then
    drugs_bought = 0
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
    drugs_bought = drugs_bought + 1
    game:set_value("drug_buy_occurence", drugs_bought)
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

-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end
