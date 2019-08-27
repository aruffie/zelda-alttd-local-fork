-- Laser projectile, mainly used by the Beamos enemy.

local enemy = ...
local projectile_behavior = require("enemies/lib/projectile")

-- Global variables
local map = enemy:get_map()
local hero = map:get_hero()

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local child_particle = nil
local new_particle_timer = nil

-- Configuration variables
local laser_particle_gap_delay = 50
local particle_speed = 400

-- Create an impact effect on hit.
function enemy:on_hit()

  local offset_x, offset_y = sprite:get_xy()
  enemy:start_brief_effect("entities/effects/impact_projectile", "default", offset_x, offset_y)
end

-- Stop scheduling particle.
function enemy:stop_scheduling_particle()

  if new_particle_timer then
    new_particle_timer:stop()
    new_particle_timer = nil
  end
  if child_particle then
    child_particle:stop_scheduling_particle()
    child_particle = nil -- Avoid to go up the chain again.
  end
end

-- Schedule the next laser particle.
function enemy:schedule_next_particle()

  local x, y, layer = enemy:get_position()
  local angle = enemy:get_angle(hero)

  new_particle_timer = sol.timer.start(enemy, laser_particle_gap_delay, function()
    new_particle_timer = nil
    local movement = enemy:get_movement()
    child_particle = map:create_enemy({
      breed = enemy:get_breed(),
      x = x,
      y = y,
      layer = layer,
      direction = enemy:get_direction4_to(hero)
    })
    child_particle:go(movement:get_angle(), movement:get_speed())
  end)
end

-- Go up all entities to tell the last one to not generate new particle anymore when one particle is removed.
enemy:register_event("on_removed", function(enemy)
  enemy:stop_scheduling_particle()
end)

-- Initialization.
function enemy:on_created()

  projectile_behavior.apply(enemy, sprite)
  enemy:set_life(1)
end

-- Restart settings.
function enemy:on_restarted()

  enemy:set_damage(2)
  enemy:set_obstacle_behavior("flying")
  enemy:set_can_hurt_hero_running(true)
  enemy:set_minimum_shield_needed(2)
  enemy:set_invincible(true)
  enemy:set_default_speed(particle_speed)
  enemy:go()
  enemy:schedule_next_particle()
  sprite:set_animation("walking")
end

