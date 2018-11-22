-- Variables
local hookable = ...

-- Event called when the custom entity is initialized.
function hookable:on_created()
  
  hookable:set_traversable_by(false)
  hookable:set_drawn_in_y_order(true)
  
end


-- Tell the hookshot that it can hook to us.
function hookable:is_hookable()
  
  return true
  
end