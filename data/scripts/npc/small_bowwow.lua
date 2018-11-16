return function(small_bowwow)
  
  local game = small_bowwow:get_game()
  local map = small_bowwow:get_map()
  local sprite = small_bowwow:get_sprite()
  local function launch_animation()
    
    local rand4 = math.random(4)
    local direction8 = rand4 * 2 - 1
    local angle = direction8 * math.pi / 4
    local m = sol.movement.create("straight")
    m:set_speed(48)
    m:set_angle(angle)
    m:set_max_distance(24 + math.random(96))
    m:start(small_bowwow)
    sprite:set_direction(rand4 - 1)
    sol.timer.stop_all(small_bowwow)
    
  end

  function small_bowwow:on_obstacle_reached(movement)

    launch_animation()

  end


  function small_bowwow:on_movement_finished(movement)

    launch_animation()

  end

  launch_animation()
  
end


