-- Bone projectile, mainly used by the spear Moblins enemies.

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

  -- Make unable to interact.
  enemy:stop_movement()
  enemy:set_invincible()
  enemy:set_can_attack(false)
  enemy:set_damage(0)

  -- Remove the entity when planted animation finished + some time.
  sprite:set_animation("reached_obstacle", function()
    sol.timer.start(enemy, planted_duration, function()
      enemy:remove()
    end)
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
  enemy:go(enemy:get_direction4_to(hero) * quarter)
end
