-- Variables
local map = ...
local game = map:get_game()
local merchant_move = false
local link_move = false

-- Include scripts
local shop_manager = require("scripts/maps/shop_manager")

-- Map events
function map:on_started(destination)

  map:init_music()
  map:init_map_entities()
  shop_manager:init(map)

end

-- Initialize the music of the map
function map:init_music()

  if game:get_value("main_quest_step") == 3  then
    sol.audio.play_music("maps/out/sword_search")
  else
    local thief_must_die = game:get_value("thief_must_die")
    if thief_must_die then
      sol.audio.play_music("maps/dungeons/boss")
    else
      sol.audio.play_music("maps/houses/shop")
    end
  end

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
 
  merchant_angry:set_enabled(false)

end

-- Discussion with Merchant
function map:talk_to_merchant() 

    local direction4 = merchant:get_direction4_to(hero)
    merchant:get_sprite():set_direction(direction4)
    --if map.shop_manager_product == nil then
    game:start_dialog("maps.houses.mabe_village.shop_2.merchant_1")
    --end

end

-- NPC events
function merchant:on_interaction()

    map:talk_to_merchant()

end

function merchant_invisible:on_interaction()

    map:talk_to_merchant()

end
