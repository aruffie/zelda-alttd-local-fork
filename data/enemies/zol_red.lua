-- Lua script of enemy zol_red.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local map = enemy:get_map()
local hero = map:get_hero()
local movement = nil

-- The enemy appears: set its properties.
function enemy:on_created()

  enemy:set_life(1)
  enemy:set_damage(2)
  enemy:set_hookshot_reaction(1)
  enemy:set_attack_consequence("boomerang", 1)
  
end

-- The enemy was stopped for some reason and should restart.
function enemy:on_restarted()

  enemy:go()

end

function enemy:go()
  
  local duration_timer = math.random(10000)
  sprite:set_animation("walking")
  movement = sol.movement.create("target")
  movement:set_speed(10)
  movement:set_target(hero)
  movement:start(enemy)
  sol.timer.start(enemy, duration_timer, function()
    enemy:jump()
  end)
  
end

function enemy:jump()

  movement:stop()
  sprite:set_animation("shaking")
  sol.timer.start(enemy, 1000, function()
    sprite:set_animation("jump")
    local direction8 = enemy:get_direction8_to(hero)
    movement = sol.movement.create("jump")
    movement:set_speed(35)
    movement:set_distance(16)
    movement:set_direction8(direction8)
    movement:start(enemy)
    function movement:on_finished()
      enemy:go()
    end
  end)
  
end



