-- Variables
local item = ...

function item:on_created()

  item:set_savegame_variable("possession_instrument_8")
  item:set_brandish_when_picked(false)

end