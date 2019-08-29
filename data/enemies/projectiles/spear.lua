-- Spear projectile, throwed horizontally or vertically, mostly used by spear Moblins enemies.

local enemy = ...
local projectile_behavior = require("enemies/lib/projectile")

-- Global variables
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5

-- Configuration variables
local planted_duration = 5000

-- Create an impact effect on hit.
function enemy:on_hit()

  local direction = enemy:get_movement():get_direction4()

  -- Make unable to interact.
  enemy:stop_movement()
  enemy:set_invincible()
  enemy:set_can_attack(false)
  enemy:set_damage(0)
  
  -- Start an effect at the impact location.
  local offset_x, offset_y = sprite:get_xy()
  enemy:start_brief_effect("entities/effects/impact_projectile", "default", offset_x, offset_y)

  -- Slightly move back.
  local movement = sol.movement.create("straight")
  movement:set_speed(64)
  movement:set_max_distance(10)
  movement:set_angle((direction + 2) % 4 * quarter)
  movement:set_smooth(false)
  movement:start(enemy)


  -- Remove the entity when planted animation finished + some time.
  sprite:set_animation("hit", function()
    enemy:remove()
  end)

  return true
end

-- Directly remove the enemy on attacking hero
enemy:register_event("on_attacking_hero", function(enemy, hero, enemy_sprite)
  enemy:remove()
end)

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
