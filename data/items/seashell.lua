-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function item:on_created()
  
  item:set_sound_when_brandished(nil)

end

function item:on_obtaining(variant, savegame_variable)

  audio_manager:play_sound("items/fanfare_item")
  item:get_game():get_item("seashells_counter"):add_amount(1)
 
end