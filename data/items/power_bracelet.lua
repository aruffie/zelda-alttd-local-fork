-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function item:on_created()

  self:set_savegame_variable("possession_power_bracelet")
  self:set_sound_when_brandished("treasure_2")

end

function item:on_variant_changed(variant)

  -- the possession state of the glove determines the built-in ability "lift"
  self:get_game():set_ability("lift", variant)

end

function item:on_using()

  self:set_finished()

end

function item:on_obtaining()
  
  audio_manager:play_sound("items/fanfare_item_extended")
        
end

