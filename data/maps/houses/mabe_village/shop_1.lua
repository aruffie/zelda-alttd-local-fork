-- Variables
local map = ...
local game = map:get_game()

-- Includes scripts
local claw_manager = require("scripts/maps/claw_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events
function map:on_started(destination)

  -- Music
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

-- NPCs events
function merchant:on_interaction()

  -- Don't make the hero pay again if the mini-game is already started.
  if merchant.playing then
    return
  end

  game:start_dialog("maps.houses.mabe_village.shop_1.merchant_1", function(answer)
    if answer == 1 then
      local money = game:get_money()
      if money > 10 then
        game:start_dialog("maps.houses.mabe_village.shop_1.merchant_3", function()
          game:remove_money(10)
          merchant.playing = true
        end)
      else
        game:start_dialog("maps.houses.mabe_village.shop_1.merchant_2")
      end
    end
  end)

end

function console:on_interaction()

  if not merchant.playing then
    return
  end

  hero:freeze()
  local claw_menu = claw_manager:create_minigame(map)
  sol.menu.start(map, claw_menu)
  function claw_menu:on_finished()
    if merchant ~= nil then
      merchant.playing = false
      hero:unfreeze()
    end
  end

end
