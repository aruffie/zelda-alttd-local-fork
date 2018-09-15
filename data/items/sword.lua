-- Sword
local item = ...
local game = item:get_game()

function item:on_created()

  self:set_savegame_variable("possession_sword")
  self:set_brandish_when_picked(false)
  self:set_shadow(nil)
end

function item:on_variant_changed(variant)

  -- The possession state of the sword determines the built-in ability "sword".
  game:set_ability("sword", variant)
  game:set_value("force_sword", variant)

end
