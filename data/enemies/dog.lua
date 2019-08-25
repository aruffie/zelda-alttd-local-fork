-- Lua script of enemy dog.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local map = enemy:get_map()
local angry = false

-- The enemy appears: set its properties.
function enemy:on_created()

  enemy:set_life(10000)
  enemy:set_damage(2)
  enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:set_hurt_style("monster")
  
end

-- The enemy was stopped for some reason and should restart.
function enemy:on_restarted()

  if angry then
    enemy:go_angry()
  else
    enemy:go_random()
  end
   
end

function enemy:on_movement_changed(movement)

  local direction4 = movement:get_direction4()
  local sprite = self:get_sprite()
  sprite:set_direction(direction4)
  
end

function enemy:on_obstacle_reached(movement)

  enemy:go_random()

end

function enemy:go_random()

  angry = false
  local sprite = enemy:get_sprite()
  local rand = math.random(100)
  if rand < 60 then
    -- Dog walking
    enemy:get_sprite():set_animation("walking")
    local movement = sol.movement.create("random")
    movement:set_speed(32)
    movement:start(enemy)
    enemy:set_can_attack(false)
  else
    -- Dog waiting
    local movement = enemy:get_movement()
    if movement then
      movement:stop()
    end
    enemy:set_can_attack(false)
    sprite:set_animation("prepare_waiting")
    function sprite:on_animation_finished(animation)
      if animation == "prepare_waiting" then
        sprite:set_animation("waiting")
      end
      sol.timer.start(enemy, 1000, function()
        enemy:go_random()
      end)
    end
  end
  
end

function enemy:go_angry()

  local game = map:get_game()
  local hero = game:get_hero()
  local direction4 = enemy:get_direction4_to(hero)
  enemy:set_can_attack(true)
  enemy:get_sprite():set_direction(direction4)
  enemy:get_sprite():set_animation("angry")
  local movement = sol.movement.create("target")
  movement:set_speed(96)
  movement:start(enemy)
  function movement:on_finished()
    enemy:go_random()
  end
    
end

function enemy:on_hurt()

  angry = true

end