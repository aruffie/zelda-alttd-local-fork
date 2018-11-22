-- Lua script of item "power bracelet".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Event called when the game is initialized.
function item:on_created()

  self:set_savegame_variable("possession_power_bracelet")
  self:set_sound_when_brandished(nil)

end

function item:on_variant_changed(variant)

  -- The possession state of the glove determines the built-in ability "lift"
  self:get_game():set_ability("lift", variant)

end

-- Event called when the hero is using this item.
function item:on_using()

  self:set_finished()

end

function item:on_obtaining()
  
  audio_manager:play_sound("items/fanfare_item_extended")
        
end

