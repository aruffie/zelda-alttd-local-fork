-- Lua script of item "instrument 1".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Event called when the game is initialized.
function item:on_created()

  item:set_savegame_variable("possession_instrument_1")
  item:set_brandish_when_picked(false)

end