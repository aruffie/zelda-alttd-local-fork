local state = sol.state.create("throwed")
state:set_can_use_item(false)
state:set_can_use_item("sword", false)
state:set_can_use_item("shield", false)
state:set_can_use_stairs(false)
state:set_can_use_teletransporter(false)
state:set_can_use_switch(false)
state:set_can_use_stream(false)
state:set_can_grab(false)
state:set_can_cut(false)
state:set_can_control_movement(false)
state:set_can_control_direction(false)
state:set_can_traverse("stairs", false)
state:set_can_traverse("crystal_block", false)
state:set_affected_by_ground("hole", false)
state:set_affected_by_ground("lava", false)
state:set_affected_by_ground("deep_water", false)
state:set_affected_by_ground("grass", false)
state:set_affected_by_ground("shallow_water", false)
state:set_affected_by_ground("prickles", false)

function state:on_started(previous_state_name, previous_state)
  
  local entity = state:get_entity()
  entity:freeze()
end

return state