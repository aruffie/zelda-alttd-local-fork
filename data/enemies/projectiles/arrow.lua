-- Arrow projectile, throwed horizontally or vertically.

local enemy = ...
local projectile_behavior = require("enemies/lib/projectile")

-- Global variables
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5

-- Configuration variables
local planted_duration = 1000

-- Create an impact effect on hit.
enemy:register_event("on_hit", function(enemy)

  -- Make unable to interact.
  enemy:stop_movement()
  enemy:set_invincible()
  enemy:set_can_attack(false)
  enemy:set_damage(0)

  -- Remove the entity when planted animation finished + some time.
  sprite:set_animation("reached_obstacle", function()
    sprite:set_paused()
    sprite:set_frame(1)
    sol.timer.start(enemy, planted_duration, function()
      enemy:remove()
    end)
  end)

  return true
end)

-- Directly remove the enemy on attacking hero
enemy:register_event("on_attacking_hero", function(enemy, hero, enemy_sprite)
  enemy:remove()
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  projectile_behavior.apply(enemy, sprite)
  enemy:set_life(1)
  enemy:set_size(8, 8)
  enemy:set_origin(4, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  sprite:set_animation("default")
  enemy:set_damage(2)
  enemy:set_obstacle_behavior("flying")
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_can_hurt_hero_running(true)
  enemy:set_minimum_shield_needed(1)
  enemy:go()
end)
