local jm={}

local y_accel = 1
local max_yvel = 5

function jm.reset_collision_rules(state)
--  print "RESET"
  if state and state:get_description() == "flying_sword" then
--    print "restoring jumping state collision rules"
    state:set_affected_by_ground("hole", true)
    state:set_affected_by_ground("lava", true)
    state:set_affected_by_ground("deep_water", true)
    state:set_affected_by_ground("prickles", true)
    state:set_can_use_stairs(true)
  end
end

function jm.setup_collision_rules(state)
--  local d = state and state:get_description() or "<none>"
--  print ("SET collision for ".. d)
  if state and (state:get_description()=="jumping" or state:get_description()=="flying_sword") then
--    print "setting up jumping state collision rules"
    state:set_affected_by_ground("hole", false)
    state:set_affected_by_ground("lava", false)
    state:set_affected_by_ground("deep_water", false)
    state:set_affected_by_ground("prickles", false)
    state:set_can_use_stairs(false)
  end
end

function jm.update_jump(entity)
  entity.y_offset=entity.y_offset or 0
  for name, sprite in entity:get_sprites() do
    if name~="shadow" then
      sprite:set_xy(0, math.min(entity.y_offset, 0))
    end
  end

  entity.y_offset= entity.y_offset+entity.y_vel
  entity.y_vel = entity.y_vel + y_accel
  if entity.y_offset >=0 then --reset sprites offset and stop jumping
    for name, sprite in entity:get_sprites() do
      sprite:set_xy(0, 0)
    end

    entity.jumping = false
    if not sol.main.get_game():is_command_pressed("attack") then
      entity:unfreeze()
    else
      jm.reset_collision_rules(entity:get_state_object())
    end
    return false
  end
  return true
end

function jm.start(entity)
  if not entity:is_jumping() then
    --   print "TOPVIEW JUMP"
    entity:set_jumping(true)
    jm.setup_collision_rules(entity:get_state_object())
--    print "JUMP"
    entity.y_vel = -max_yvel
    sol.timer.start(entity, 30, function()
        local r=jm.update_jump(entity)
        if not r then
          return false
        end
        return true
      end)
  end
end

function jm.init(name)
  local state = sol.state.create(name)
  state:set_can_use_item(false)
  state:set_can_control_movement(true)
  state:set_can_control_direction(false)
  state:set_can_traverse("stairs", false)

  return state
end

return jm