-- Lua script of item "beak of stone".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

function item:on_created()

  item:set_savegame_variable("possession_photos_counter")
  item:set_amount_savegame_variable("amount_photos_counter")
  item:set_assignable(false)
  
end