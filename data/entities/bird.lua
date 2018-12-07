-- Variables
local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local movement

-- Event called when the custom entity is initialized.
function entity:on_created()

  entity:start_movement()
  sol.timer.start(entity, 50, function()
    local direction = movement:get_direction4()
    entity:get_sprite():set_direction(direction)
    return true
  end)

end

-- Start movement
function entity:start_movement()

  entity:go_random()
  local duration = 1000 + math.random(1000)
  sol.timer.start(entity, duration, function()
    entity:stop_movement()
  end)

end

-- Stop movement
function entity:stop_movement()

  local duration = 1000 + math.random(1000)
  entity:get_sprite():set_animation("waiting")
  movement:stop()
  sol.timer.start(entity, duration, function()
    entity:start_movement()
  end)

end

-- launch random movement
function entity:go_random()

  entity:get_sprite():set_animation("walking")
  movement = sol.movement.create("random")
  movement:set_speed(16)
  movement:start(entity)
  
end