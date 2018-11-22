-- Variables
local item = ...

function item:on_created()

  item:set_can_disappear(true)
  item:set_brandish_when_picked(false)
  sitemelf:set_savegame_variable("possession_bomb")

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

