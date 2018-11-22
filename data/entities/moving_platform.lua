-- Variables
local entity = ...
local movement
local angle = 0
local direction = 0
local sprite

-- Event called when the custom entity is initialized.
function entity:on_created()
  
  sprite = entity:get_sprite()
  entity:set_traversable_by(false)
  distance = self:get_property("distance")
  if distance == nil then
    distance = 0
  end
  angle = sprite:get_direction() * math.pi / 2
  
  entity:go()

end


function entity:go()

  -- Set the movement.
  movement = sol.movement.create("straight")
  movement:set_speed(60)
  movement:set_max_distance(distance)
  movement:set_angle(angle)
  movement:start(moving_platform)
  function movement:on_finished()
    angle = angle + math.pi
    moving_platform:go()
  end
  function movement:on_obstacle_reached()
    angle = angle + math.pi
    moving_platform:go()
  end
  
end