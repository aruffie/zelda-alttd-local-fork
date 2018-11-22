-- Lua script of item "seashells counter".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Event called when the game is initialized.
function item:on_created()

  self:set_savegame_variable("possession_seashells_counter")
  self:set_amount_savegame_variable("amount_seashells_counter")
  self:set_assignable(false)

end