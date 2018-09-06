local enemy = ...

-- Fireball: an invincible enemy that moves in horizontal or vertical direction
-- and that runs along the walls

local last_direction4 = 0
local clockwise = false

-- The enemy appears: set its properties.
function enemy:on_created()

  self:set_life(1)
  self:set_damage(1)
  self:create_sprite("enemies/" .. enemy:get_breed())
  self:set_size(8, 8)
  self:set_origin(4, 4)
  self:set_can_hurt_hero_running(true)
  self:set_invincible()
  self:set_obstacle_behavior("swimming")
  clockwise = (self:get_property("clockwise") == "true")

end

-- The enemy was stopped for some reason and should restart.
function enemy:on_restarted()

  local direction4 = 0
  if not clockwise then
    direction4 = 2
  end
  self:go(direction4)

end

function enemy:change_direction(tries)

  if tries ~= nil then
    local dxy = {
                { x =  1, y =  0},
                { x =  0, y = -1},
                { x = -1, y =  0},
                { x =  0, y =  1}
              }

    -- The current direction is last_direction4:
    local try_clockwise = (last_direction4 - 1) % 4
    local try_counterclockwise = (last_direction4 + 1) % 4
    local try_turnaround = (last_direction4 + 2) % 4
    local direction_found = false
    for _, try in pairs(tries) do
      if direction_found == false and not self:test_obstacles(dxy[try + 1].x, dxy[try + 1].y) then
          self:go(try)
          direction_found = true
      end
    end
  end

end

-- An obstacle is reached: make the Fireball bounce.
function enemy:on_obstacle_reached()

  local tries
  if clockwise then
    tries = { try_clockwise, try_counterclockwise, try_turnaround }
  else
    tries = { try_counterclockwise, try_clockwise, try_turnaround }
  end
  self:change_direction(tries)

end


-- Makes the Fireball go towards a horizontal or vertical direction.
function enemy:go(direction4)

  local m = sol.movement.create("straight")
  m:set_speed(80)
  m:set_smooth(false)
  m:set_angle(direction4 * math.pi / 2)
  m:start(self)
  function m:on_position_changed()
    local tries
    if clockwise then
      tries = { try_clockwise}
    else
      tries = { try_counterclockwise}
    end
    enemy:change_direction(tries)
  end
  last_direction4 = direction4

end