local entity = ...

-- Event called when the custom entity is initialized.
function entity:on_created()
  
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)

end