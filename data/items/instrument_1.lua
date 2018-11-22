-- Lua script of item "instrument 1".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Event called when the game is initialized.
function item:on_created()

  item:set_savegame_variable("possession_instrument_1")
  item:set_brandish_when_picked(false)

end

function item:on_obtaining(variant, savegame_variable)

  -- Savegame  
  item:get_game():set_value("main_quest_step", 8)

end