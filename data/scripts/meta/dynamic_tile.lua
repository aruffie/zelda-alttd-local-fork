-- Initialize dynamic tile behavior specific to this quest.

-- Variables
local dynamic_tile_meta = sol.main.get_metatable("dynamic_tile")

function dynamic_tile_meta:on_created()

  if self:get_property("draw_in_y_order") then
    self:set_drawn_in_y_order(true)
  end
  local name = self:get_name()
  if name == nil then
    return
  end

  if name:match("^invisible_tile") then
    self:set_visible(false)
  end
  
  
end

return true
