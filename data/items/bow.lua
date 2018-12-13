-- Lua script of item "bow".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Event called when the game is initialized.
function item:on_created()

  item:set_savegame_variable("possession_bow")
  item:set_amount_savegame_variable("amount_bow")
  item:set_assignable(true)

end

-- Event called when the hero is using this item.
function item:on_using()

  if item:get_amount() == 0 then
    audio_manager:play_sound("misc/error")
  else
    -- we remove the arrow from the equipment after a small delay because the hero
    -- does not shoot immediately
    sol.timer.start(300, function()
      item:remove_amount(1)
    end)
    item:get_map():get_entity("hero"):start_bow()
  end
  item:set_finished()

end

function item:on_amount_changed(amount)

  if item:get_variant() ~= 0 then
    if amount == 0 then
      item:set_variant(1)
    else
      item:set_variant(2)
    end
  end

end

function item:on_obtaining(variant, savegame_variable)

  local quiver = itrm:get_game():get_item("quiver")
  if not quiver:has_variant() then
    quiver:set_variant(1)
  end

end

