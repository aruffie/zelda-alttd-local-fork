-- Lua script of item "magnifying lens".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Event called when the game is initialized.
function item:on_created()

  item:set_savegame_variable("possession_magnifiyng_lens")
  item:set_sound_when_brandished(nil)

end

function item:on_obtaining(variant, savegame_variable)

  -- Sound
  audio_manager:play_sound("items/fanfare_item_extended")
  -- Savegame
  local variant = self:get_variant()
  if variant == 6 then
    item:get_game():set_value("main_quest_step", 20)
  elseif variant == 7 then
    item:get_game():set_value("main_quest_step", 21)
  end

end