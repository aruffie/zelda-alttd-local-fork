-- Variables
local map = ...
local game = map:get_game()
local is_game_available = false

-- Includes scripts
local claw_manager = require("scripts/maps/claw_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events
function map:on_started(destination)

  map:init_music()

end

-- Initialize the music of the map
function map:init_music()

  if game:get_value("main_quest_step") == 3  then
    audio_manager:play_music("07_koholint_island")
  else
    audio_manager:play_music("15_trendy_game")
  end

end

-- Discussion with Merchant
function map:talk_to_merchant() 

  game:start_dialog("maps.houses.mabe_village.shop_1.merchant_1", function(answer)
    if answer == 1 then
      local money = game:get_money()
      if money > 10 then
        game:start_dialog("maps.houses.mabe_village.shop_1.merchant_3", function()
          money = money - 10
          game:set_money(money)
          is_game_available = true
        end)
      else
        game:start_dialog("maps.houses.mabe_village.shop_1.merchant_2")
      end
    end
  end)

end

-- NPCs events
function merchant:on_interaction()

      map:talk_to_merchant()

end

function console:on_interaction()

  if is_game_available then
    is_game_available = false
    claw_manager:init_map(map)
  end

end
