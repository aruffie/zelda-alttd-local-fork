local jm={}

local y_accel = 0.1
local max_yvel = 2

local debug_start_x, debug_start_y
local debug_max_height = 0

local audio_manager=require("scripts/audio_manager")
function jm.reset_collision_rules(state)
--  print "RESET"
  if state and (state:get_description() == "flying_sword" or state:get_description()=="running") then
--    print "restoring jumping state collision rules"
    state:set_affected_by_ground("hole", true)
    state:set_affected_by_ground("lava", true)
    state:set_affected_by_ground("deep_water", true)
    state:set_affected_by_ground("prickles", true)
    state:set_can_use_stairs(true)
    state:set_can_use_teletransporter(true)
    state:set_can_use_switch(true)
    state:set_can_use_stream(true)
  end
end

function jm.setup_collision_rules(state)
--  local d = state and state:get_description() or "<none>"
--  print ("SET collision for ".. d)
  if state and (state:get_description()=="jumping" or state:get_description()=="flying_sword" or state:get_description()=="running") then
--    print "setting up jumping state collision rules"
    state:set_affected_by_ground("hole", false)
    state:set_affected_by_ground("lava", false)
    state:set_affected_by_ground("deep_water", false)
    state:set_affected_by_ground("prickles", false)
    state:set_can_use_stairs(false)
    state:set_can_use_teletransporter(false)
    state:set_can_use_switch(false)
    state:set_can_use_stream(false)
  end
end

function jm.update_jump(entity)
  entity.y_offset=entity.y_offset or 0
  for name, sprite in entity:get_sprites() do
    if name~="shadow" and name~="custom_shadow" then
      sprite:set_xy(0, math.min(entity.y_offset, 0))
    end
  end

  entity.y_offset= entity.y_offset+entity.y_vel
  debug_max_height=math.min(debug_max_height, entity.y_offset)
  entity.y_vel = entity.y_vel + y_accel
  if entity.y_offset >=0 then --reset sprites offset and stop jumping
    for name, sprite in entity:get_sprites() do
      sprite:set_xy(0, 0)
    end
    local final_x, final_y=entity:get_position()
    print("Distance reached during jump: X="..final_x-debug_start_x..", Y="..final_y-debug_start_y..", height="..debug_max_height ..", final state="..entity:get_state())
    entity.jumping = false
    if entity:get_state()~="custom" or entity:get_state_object():get_description()~="running" and not sol.main.get_game():is_command_pressed("attack") then
      entity:unfreeze()
    else
      jm.reset_collision_rules(entity:get_state_object())
    end
    return false
  end
  return true
end

function jm.start(entity)
  print (entity:get_type())
  if not entity:is_jumping() then
    audio_manager:play_sound("hero/jump")
    debug_start_x, debug_start_y=entity:get_position()
    --   print "TOPVIEW JUMP"
    entity:set_jumping(true)
    jm.setup_collision_rules(entity:get_state_object())
--    print "JUMP"
    entity.y_vel = -max_yvel
    sol.timer.start(entity, 10, function()
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