-- Variables
local entity = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")
require("scripts/multi_events")

-- Event called when the custom entity is initialized.
function entity:on_created()
  
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)
  entity:set_weight(2)
  local sprite = entity:get_sprite()
  local game = entity:get_game()
  entity:register_event("on_removed", function(sprite, animation)
    audio_manager:play_sound("misc/rock_shatter")
  end)
  
end