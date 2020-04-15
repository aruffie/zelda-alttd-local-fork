local pickable_meta=sol.main.get_metatable("pickable")
local entity_manager= require("scripts/maps/entity_manager")
require "scripts/multi_events"

pickable_meta:register_event("on_removed", function(pickable)
    
  local item=pickable:get_treasure()
  if item:get_name()=="small_key" then
    local ground=pickable:get_ground_below()
    if ground=="hole" then
      entity_manager:create_falling_entity(pickable)
    end
  end
  
end)