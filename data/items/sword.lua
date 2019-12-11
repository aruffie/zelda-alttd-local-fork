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
  --item:get_game():set_ability("sword", 1)
  local hero=item:get_game():get_hero()
  --Cleanup old sword sprite, if any
  if hero:get_sprite("sword_override") then
    hero:remove_sprite(hero:get_sprite("sword_override"))
  end
  if hero:get_sprite("sword_stars_override") then
    hero:remove_sprite(hero:get_sprite("sword_stars_override"))
  end
  --Set new sprite
  hero:create_sprite("hero/sword"..variant, "sword_override")
  hero:create_sprite("hero/sword_stars"..variant, "sword_stars_override")
  item:get_game():set_ability("sword", 0)
  item:get_game():set_value("force_sword", variant)

end
