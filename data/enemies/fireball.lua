local enemy = ...

-- Fireball: an invincible enemy that moves in horizontal or vertical direction
-- and that runs along the walls

local last_direction4 = 0
local clockwise = true

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

end

-- The enemy was stopped for some reason and should restart.
function enemy:on_restarted()

  direction4 = enemy:get_direction()
  self:go(direction4)
end

-- An obstacle is reached: make the Bubble bounce.
function enemy:on_obstacle_reached()

  local dxy = {
    { x =  1, y =  0},
    { x =  0, y = -1},
    { x = -1, y =  0},
    { x =  0, y =  1}
  }

  -- The current direction is last_direction8:
  -- try the three other diagonal directions.
  local try1 = (last_direction4 + 2) % 4
  local try2 = (last_direction4 + 4) % 4
  local try3 = (last_direction4 + 6) % 4

  if not self:test_obstacles(dxy[try1 + 1].x, dxy[try1 + 1].y) then
    self:go(try1)
  elseif not self:test_obstacles(dxy[try2 + 1].x, dxy[try2 + 1].y) then
    self:go(try2)
  else
    self:go(try3)
  end
end

-- Makes the Bubble go towards a diagonal direction (1, 3, 5 or 7).
function enemy:go(direction4)

  local m = sol.movement.create("straight")
  m:set_speed(80)
  m:set_smooth(false)
  m:set_angle(direction4 * math.pi / 2)
  m:start(self)
  last_direction4 = direction4
end