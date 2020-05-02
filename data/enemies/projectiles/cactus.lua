-- Cactus projectile, throwed away to the hero and bounce on obstacles, mostly used by pokey enemies.

local enemy = ...
local projectile_behavior = require("enemies/lib/projectile")

-- Global variables
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/pokey/body")
local quarter = math.pi * 0.5
local bounce_count = 0
local angle

-- Configuration variables
local speed = 128
local bounce_before_delete = 3

-- Start going away to the hero and bounce.
function enemy:go(new_angle)

  angle = new_angle or hero:get_angle(enemy)
  enemy:straight_go(angle, speed)
end

-- Create an impact effect on hit.
enemy:register_event("on_hit", function(enemy)

  bounce_count = bounce_count + 1
  enemy:go(enemy:get_obstacles_bounce_angle(angle))
  return bounce_count >= bounce_before_delete
end)

-- Directly remove the enemy on attacking hero
enemy:register_event("on_attacking_hero", function(enemy, hero, enemy_sprite)
  enemy:start_death()
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  projectile_behavior.apply(enemy, sprite)
  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  sprite:set_animation("walking")
  enemy:set_invincible()
  enemy:set_damage(2)
  enemy:set_obstacle_behavior("flying")
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_can_hurt_hero_running(true)
  enemy:set_minimum_shield_needed(1)
  enemy:go()
end)
