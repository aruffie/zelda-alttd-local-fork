-- Lua script of item "magic powder".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Event called when the game is initialized.
function item:on_created()

  self:set_savegame_variable("possession_magic_powder")
  self:set_brandish_when_picked(false)

end

-- Event called when the hero is using this item.
function item:on_using()

  self:set_finished()

end
