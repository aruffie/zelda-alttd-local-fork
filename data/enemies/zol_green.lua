local enemy = ...

-- Zol green

enemy:set_life(1)
enemy:set_damage(1)

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local max_distance = 50
local is_awake = false

function enemy:on_created()

end

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
      sprite:set_animation("shaking")
      sol.timer.start(enemy, 1000, function()
        enemy:go()
      end)
    end
  end

end

function enemy:disappear()

  is_awake = false
  sprite:set_animation("disappearing")
  function sprite:on_animation_finished(animation)
    if animation == "disappearing" then
     sprite:set_animation("invisible")
    end
  end

end


function enemy:go()

  sprite:set_animation("immobilized")
  sol.timer.start(enemy, 200, function()
    sprite:set_animation("jump")
    local direction8 = enemy:get_direction8_to(enemy:get_map():get_hero())
    local m = sol.movement.create("jump")
    m:set_speed(35)
    m:set_distance(16)
    m:set_direction8(direction8)
    m:start(enemy)
    function m:on_finished()
      sprite:set_animation("immobilized")
      sol.timer.start(enemy, 500, function()
        local tx, ty, _ = enemy:get_map():get_hero():get_position()
        if enemy:get_distance(tx, ty) < max_distance then
          enemy:go()
        else
          enemy:disappear()
        end
      end)
    end
  end)
  

end



