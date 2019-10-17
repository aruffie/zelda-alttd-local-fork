-- Lua script of item "magic powder bag".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Event called when the game is initialized.
function item:on_created()

  self:set_savegame_variable("possession_magic_powder_bag")
  
end

function item:on_started()

  self:on_variant_changed(self:get_variant())
  
end

function item:on_variant_changed(variant)

  -- The quiver determines the maximum amount of the bow.
  local magic_powder_counter = self:get_game():get_item("magic_powder_counter")
  if variant == 0 then
    magic_powder_counter:set_max_amount(0)
  else
    local max_amounts = {20, 40}
    local max_amount = max_amounts[variant]
    -- Set the max value of the bow counter.
    magic_powder_counter:set_variant(1)
    magic_powder_counter:set_max_amount(max_amount)
  end
  
end

function item:on_obtaining(variant, savegame_variable)

  audio_manager:play_sound("items/fanfare_item")
  if variant > 0 then
    local magic_powder_counter = self:get_game():get_item("magic_powder_counter")
    magic_powder_counter:set_amount(magic_powder_counter:get_max_amount())
  end
  
end

