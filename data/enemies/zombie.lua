local enemy = ...
local max_distance = 100
local is_awake = false

-- Zombie

enemy:set_life(1)
enemy:set_damage(1)

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())

-- The enemy was stopped for some reason and should restart.
function enemy:on_restarted()
  
  sprite:set_animation("invisible")
  sol.timer.start(enemy, 50, function()
    local tx, ty, _ = enemy:get_map():get_hero():get_position()
    if enemy:get_distance(tx, ty) < max_distance then
      if is_awake == false then
        enemy:appear()
      end
    end
    return true
  end)

end

function enemy:appear()

  is_awake = true
  sprite:set_animation("appearing")
  function sprite:on_animation_finished(animation)
    if animation == "appearing" then
      enemy:go()
    end
  end

end

function enemy:disappear()

  sol.timer.start(enemy, 3000, function()
  is_awake = false
  end)
  sprite:set_animation("disappearing")
  function sprite:on_animation_finished(animation)
    if animation == "disappearing" then
     sprite:set_animation("invisible")
    end
  end

end

-- Makes the enemy walk towards a direction.
function enemy:go(direction4)

    local distance = 36
    local random = math.random(100)
    distance = distance + random
    local direction = enemy:get_direction4_to(enemy:get_map():get_hero())
    sprite:set_animation("walking")
    sprite:set_direction(direction)
    local angle = enemy:get_angle(enemy:get_map():get_hero())
    local m = sol.movement.create("straight")
    m:set_speed(50)
    m:set_max_distance(distance)
    m:set_angle(angle)
    m:start(enemy)
    function m:on_finished()
      enemy:disappear()
    end
    function m:on_obstacle_reached()
      m:stop()
      enemy:disappear()
    end

end



