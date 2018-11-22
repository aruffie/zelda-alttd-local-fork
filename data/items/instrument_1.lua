-- Variables
local item = ...

function item:on_created()

  item:set_savegame_variable("possession_instrument_1")
  item:set_brandish_when_picked(false)

end

function item:on_obtaining(variant, savegame_variable)

  -- Savegame  
  item:get_game():set_value("main_quest_step", 8)

end