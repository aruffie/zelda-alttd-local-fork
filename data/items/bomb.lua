-- Lua script of item "bomb".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Event called when the game is initialized.
function item:on_created()

  item:set_can_disappear(true)
  item:set_brandish_when_picked(false)
  item:set_savegame_variable("possession_bomb")

end

function item:on_obtaining(variant, savegame_variable)

  -- Obtaining bombs increases the bombs counter.
  local amounts = {1, 10}
  local amount = amounts[variant]
  if amount == nil then
    error("Invalid variant '" .. variant .. "' for item 'bomb'")
  end
  item:get_game():get_item("bombs_counter"):add_amount(amount)

end

