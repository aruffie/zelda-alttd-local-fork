local enemy = ...

-- Molblin: goes in a random direction.

enemy:set_life(1)
enemy:set_damage(1)

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local max_distance = 50
local is_awake = false

function enemy:on_created()

  enemy:set_obstacle_behavior("flying")
end

-- The enemy was stopped for some reason and should restart.
function enemy:on_restarted()

  sprite:set_animation("stopped")
  sol.timer.start(enemy, 50, function()
    local tx, ty, _ = enemy:get_map():get_hero():get_position()
    if enemy:get_distance(tx, ty) < max_distance then
      if is_awake == false then
        enemy:go()
      end
    end
    return true
  end)

end

function enemy:go()
  

end



