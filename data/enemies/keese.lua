local enemy = ...

enemy.flying_height = 10

-- Molblin: goes in a random direction.

enemy:set_life(1)
enemy:set_damage(1)

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local max_distance = 50
local is_awake = false

function enemy:on_created()

  enemy:set_obstacle_behavior("flying") -- Fly above bad grounds.
  enemy:set_layer_independent_collisions(true) -- Fly above non-traversable entities.
end

-- The enemy was stopped for some reason and should restart.
function enemy:on_restarted()

  sprite:set_animation("stopped")
  sol.timer.start(enemy, 50, function()
    local hero = enemy:get_map():get_hero()
    if (not is_awake) and enemy:get_distance(hero) < max_distance then
      enemy:go()
    end
    return true
  end)
end

function enemy:go()

  is_awake = true
  self:get_sprite():set_animation("walking")
  local hero = self:get_map():get_hero()

  local movement = sol.movement.create("path_finding")
  movement:set_speed(32)
  movement:set_target(hero)
  movement:set_ignore_obstacles(true)
  movement:start(enemy)
  sol.timer.start(enemy, 1500, function()
    self:get_sprite():set_animation("stopped")
    movement:stop()
    is_awake = false
  end)
end



