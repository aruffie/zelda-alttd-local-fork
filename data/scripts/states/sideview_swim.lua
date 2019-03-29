local state = sol.state.create("sideview_swim")
state:set_can_use_sword(true)
state:set_can_use_item(false)
state:set_can_use_item("feather", true)
state:set_can_control_movement(true)
state:set_can_control_direction(false)

local hero_meta=sol.main.get_metatable("hero")
function hero_meta:start_swimming()
  self:start_state(state)
end

function state:on_update()
  -- print "i'm swiiiiiiiming in the poool, just swiiiiiming in the pool"
  local entity=state:get_entity()
  local map = state:get_map()
  local x,y,layer=entity:get_position()
  if map:get_ground(x,y,layer)~="deep_water" then
    entity:unfreeze()
  end
end