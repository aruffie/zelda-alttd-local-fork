-- Stone projectile, throwed horizontally or vertically, mostly used by octorok enemies.

local enemy = ...
local projectile_behavior = require("enemies/lib/projectile")

-- Global variables
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5

-- COnfiguration variables
local before_removing_delay = 500

-- Start going to the hero by an horizontal or vertical move.
function enemy:go()
  enemy:straight_go(sprite:get_direction() * quarter)
end

-- Create an impact effect on hit.
enemy:register_event("on_hit", function(enemy)
  enemy:start_brief_effect("entities/effects/impact_stone", "default", sprite:get_xy())
end)

-- Directly remove the enemy on attacking hero
enemy:register_event("on_attacking_hero", function(enemy, hero, enemy_sprite)
  enemy:silent_kill()
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  projectile_behavior.apply(enemy, sprite)
  enemy:set_life(1)
  enemy:set_size(4, 4)
  enemy:set_origin(2, 2)
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
