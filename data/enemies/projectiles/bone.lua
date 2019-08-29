-- Bone projectile, mainly used by the red Stalfos enemy.

local enemy = ...
local projectile_behavior = require("enemies/lib/projectile")

-- Global variables
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())

-- Create an impact effect on hit.
function enemy:on_hit()

  local offset_x, offset_y = sprite:get_xy()
  enemy:start_brief_effect("entities/effects/impact_projectile", "default", offset_x, offset_y)
end

-- Initialization.
function enemy:on_created()

  projectile_behavior.apply(enemy, sprite)
  enemy:set_life(1)
end

-- Restart settings.
function enemy:on_restarted()

  sprite:set_animation("default")
  enemy:set_damage(2)
  enemy:set_obstacle_behavior("flying")
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_can_hurt_hero_running(true)
  enemy:set_minimum_shield_needed(1)
  enemy:go()
end
