local enemy = ...

-- Molblin: goes in a random direction.

enemy:set_life(2)
enemy:set_damage(1)

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())

function enemy:on_created()

    self:set_can_be_pushed_by_shield(true)

end

-- The enemy was stopped for some reason and should restart.
function enemy:on_restarted()

  local m = sol.movement.create("straight")
  m:set_speed(100)
  m:start(self)
  local direction4 = math.random(4) - 1
  self:go(direction4)

end

function enemy:on_movement_finished(movement)

  local direction4 = math.random(4) - 1
  self:go(direction4)

end

function enemy:on_obstacle_reached(movement)

  local direction4 = math.random(4) - 1
  self:go(direction4)

end

-- Makes the enemy walk towards a direction.
function enemy:go(direction4)
 
  -- Set the sprite.
  sprite:set_animation("walking")
  sprite:set_direction(direction4)

  -- Set the movement.
  local speed = 15
  if direction4 == 0 or direction4 == 2 then
    speed = 75
  end
  local m = self:get_movement()
  local max_distance = 40 + math.random(120)
  m:set_max_distance(max_distance)
  m:set_smooth(true)
  m:set_speed(speed)
  m:set_angle(direction4 * math.pi / 2)

end

