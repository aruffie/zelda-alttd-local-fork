local enemy = ...

-- Molblin: goes in a random direction.

enemy:set_life(1)
enemy:set_damage(1)

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local max_distance = 50
local is_awake = false

function enemy:on_created()

end

-- The enemy was stopped for some reason and should restart.
function enemy:on_restarted()

  sprite:set_animation("stopped")
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
      sprite:set_animation("shaking")
    elseif animation == 'shaking' then
      enemy:go()
    end
  end

end

function enemy:go()

  sprite:set_animation("immobilized")
  sol.timer.start(enemy, 200, function()
    local m = sol.movement.create("jump")
    m:set_speed(0)
    m:set_distance(32)
    m:set_direction(0)
    m:start(enemy)
  end)
  

end



