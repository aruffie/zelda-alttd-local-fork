-- Small bow wow
local enemy = ...
local sprite = enemy:create_sprite("enemies/small_bowwow")

function enemy:on_created()

  self:set_invincible(true)
  self:set_can_attack(false)
  self:set_damage(0)
  self:set_hurt_style("normal")
  self:set_size(16, 16)
  self:set_origin(8, 13)

end

function enemy:on_restarted()

  self:go_random()

end

function enemy:on_movement_finished(movement)

  self:go_random()

end

function enemy:on_obstacle_reached(movement)

  self:go_random()

end

function enemy:go_random()

  -- Random diagonal direction.
  local rand4 = math.random(4)
  local direction8 = rand4 * 2 - 1
  local angle = direction8 * math.pi / 4
  local m = sol.movement.create("straight")
  m:set_speed(48)
  m:set_angle(angle)
  m:set_max_distance(24 + math.random(96))
  m:start(self)
  sprite:set_direction(rand4 - 1)
  sol.timer.stop_all(self)
  sol.timer.start(self, 300 + math.random(1500), function()
  end)

end

function sprite:on_animation_finished(animation)

  if animation == "bite" then
    self:set_animation("walking")
  end

end
