-- Flowerball projectile, mainly used by the red Stalfos enemy.

local enemy = ...
local projectile_behavior = require("enemies/lib/projectile")

-- Global variables
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())

-- Start going to the hero.
function enemy:go()
  local movement = enemy:straight_go(nil, 80)

  -- Ignore obstacle and remove enemy when not visible anymore.
  movement:set_ignore_obstacles(true)
  function movement:on_position_changed()
    if not enemy:is_watched(sprite) then
      enemy.is_silent = true -- Workaround : Don't play sounds added by enemy meta script.
      enemy:hurt(enemy:get_life()) -- Kill the enemy instead of removing it to trigger dying events.
    end
  end
end

-- Create an impact effect on hit.
enemy:register_event("on_hit", function(enemy)
  enemy:start_brief_effect("entities/effects/impact_projectile", "default", sprite:get_xy())
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
  enemy:set_layer_independent_collisions(true)
  enemy:set_obstacle_behavior("flying")
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_can_hurt_hero_running(true)
  enemy:set_minimum_shield_needed(1)
  enemy:go()
end)
