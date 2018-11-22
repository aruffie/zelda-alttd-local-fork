-- Variables
local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()
  
  entity:set_traversable_by(false)

end
