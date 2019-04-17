local state = sol.state.create("dummy")

state:set_can_use_stairs(false)
state:set_can_traverse("stairs", false)
state:set_can_control_movement(true)
state:set_can_control_direction(false)

function state:on_started()
  print "DUMMIER !!!!!!!!"
end

function state:on_finished()
  print "no more dummy !?"
end

return function(e)
  print "DUMMMMMYYYYY ??????"
  e:start_state(state)
  sol.timer.start(e:get_map(), 1000, function()
      print "Du... mmy ?"
       state:set_can_use_stairs(true)
    end)
end

