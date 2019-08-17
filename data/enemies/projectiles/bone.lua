-- Bone projectile, mainly used by the red Stalfos enemy.

local enemy = ...
local projectile_behavior = require("enemies/lib/projectile")

-- Global variables
local main_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())

-- Initialization.
function enemy:on_created()

  projectile_behavior.apply(enemy)
  enemy:set_life(1)
end

-- Restart settings.
function enemy:on_restarted()

  main_sprite:set_animation("default")
  enemy:set_damage(2)
  enemy:set_obstacle_behavior("flying")
  enemy:set_can_hurt_hero_running(true)
  enemy:set_minimum_shield_needed(1)
  enemy:set_invincible()
  enemy:go()
end
