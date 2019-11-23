-- Lua script of item "sword".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

function item:on_created()

  item:set_savegame_variable("possession_sword")
  item:set_brandish_when_picked(false)
  item:set_shadow(nil)

end

function item:on_variant_changed(variant)

  -- The possession state of the sword determines the built-in ability "sword".
  local hero=item:get_game():get_hero()
--  hero:create_sprite("hero/sword"..variant, "sword")
--  hero:create_sprite("hero/sword_stars"..variant, "sword_stars")
  item:get_game():set_ability("sword", 1)
  item:get_game():set_value("force_sword", variant)

end
