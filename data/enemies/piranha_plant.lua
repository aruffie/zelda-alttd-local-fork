-- Lua script of enemy "piranha_plant".
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...

-- The enemy appears: set its properties.
function enemy:on_created()

  enemy:set_life(1)
  enemy:set_damage(1)
  enemy:set_pushed_back_when_hurt(false)
  enemy:create_sprite("enemies/" .. enemy:get_breed())
  
end

-- The enemy was stopped for some reason and should restart.
function enemy:on_restarted()

  sol.timer.start(enemy, 1000, function()
    enemy:exit()
  end)
  
end

-- The enemy enters the pipe
function enemy:enter()
  
  enemy:get_sprite():set_animation("enter", function()
    sol.timer.start(enemy, 3000, function()
      enemy:exit()
    end)
  end)
  
end

-- The enemy comes out of the pipe
function enemy:exit()
  
  enemy:get_sprite():set_animation("exit", function()
    enemy:get_sprite():set_animation("waiting")
    sol.timer.start(enemy, 3000, function()
      enemy:enter()
    end)  
  end)
  
end


