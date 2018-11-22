-- Variables
local entity = ...

-- Event called when the custom entity is initialized.
function entity:on_created()
  
  entity:set_modified_ground("hole")
  
end