-- Shovel
local item = ...

function item:on_created()

  self:set_savegame_variable("item_shovel")

end

function item:on_using()

end

