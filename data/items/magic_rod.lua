-- Shovel
local item = ...

function item:on_created()

  self:set_savegame_variable("item_magic_rod")
  self:set_assignable(true)

end

