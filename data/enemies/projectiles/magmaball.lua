-- Bone projectile, mainly used by the red Stalfos enemy.

local enemy = ...
local projectile_behavior = require("enemies/lib/projectile")

-- Global variables
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())

-- Start going to the hero.
function enemy:go()
  enemy:straight_go()
  enemy:get_movement():set_ignore_obstacles(true)
end

-- Create an impact effect on hit.
enemy:register_event("on_hit", function(enemy)

  local offset_x, offset_y = sprite:get_xy()
  enemy:start_brief_effect("entities/effects/impact_projectile", "default", offset_x, offset_y)
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  projectile_behavior.apply(enemy, sprite)
  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 8)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  sprite:set_animation("walking")
  enemy:set_damage(2)
  enemy:set_obstacle_behavior("flying")
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_can_hurt_hero_running(true)
  enemy:set_minimum_shield_needed(1)
  enemy:go()
end)
