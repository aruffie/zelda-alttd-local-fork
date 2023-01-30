-- Lua script of item "compass".
-- This script is executed only once for the whole game.

-- Variables
local item = ...
local game = item:get_game()

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Event called when the game is initialized.
function item:on_created()

  self:set_sound_when_brandished(nil)
  self:set_brandish_when_picked(false)
  self:set_savegame_variable("possession_claw_game_treasure")

end

function item:on_obtaining(variant, savegame_variable)

 -- audio_manager:play_sound("items/get_item2")
  local variant = item:get_variant()
  game:start_dialog("maps.houses.mabe_village.shop_1.retrieve_claw_game_treasure_" .. variant, function()
    -- Heart item.
    if variant == 1 then
        game:set_life(game:get_max_life())
    -- Rupee item
    elseif variant == 2 then
        self:get_game():add_money(30)
    -- Shield item
    elseif variant == 3 then
      local shield = game:get_item("shield")
      shield:set_variant(1)
    else
      local amount =   magic_powder_counter:get_amount()
      amount = amount + 10
      magic_powder_counter:set_amount(amount)
    end
  end)
  
end

