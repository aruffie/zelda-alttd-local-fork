-- Lua script of item "photo".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Event called when the game is initialized.
function item:on_created()

  item:set_can_disappear(true)
  item:set_brandish_when_picked(false)

end

function item:on_obtaining(variant, savegame_variable)

  item:get_game():get_item("photos_counter"):add_amount(1)

end