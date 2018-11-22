-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function item:on_created()

  item:set_shadow("small")
  item:set_brandish_when_picked(false)
  item:set_sound_when_picked(nil)
  
end

function item:on_obtaining(variant, savegame_variable)

  -- Sound
  audio_manager:play_sound("items/get_item2")
  -- Add key
  item:get_game():add_small_key()
  
end