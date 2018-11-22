-- Variables
local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()

  local shovel = game:get_item("shovel")
  local x, y, width, height = entity:get_bounding_box()
  local layer = entity:get_layer()
  local index = shovel:get_index_from_position(x, y, layer)

  local index_1, index_2, index_3, index_4 = shovel:get_four_indexes(index)
  map:set_digging_allowed_square(index_1, false)
  map:set_digging_allowed_square(index_2, false)
  map:set_digging_allowed_square(index_3, false)
  map:set_digging_allowed_square(index_4, false)
  entity:remove()
  
end
