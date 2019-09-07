-- Lua script of enemy coconut, mainly used by the Monkey enemy.

-- Global variables
local enemy = ...
local projectile_behavior = require("enemies/lib/projectile")

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local circle = 2.0 * math.pi
local bounce_count = 0

-- Configuration variables
local maximum_bounce = 4
local minimum_speed = 40
local maximum_speed = 80

-- Make the enemy bounce and go to a random target.
function enemy:go(angle, speed)
  enemy:bounce_go(angle or math.random() * circle, speed or math.random(minimum_speed, maximum_speed))
  enemy:get_movement():set_ignore_obstacles(true)
end

-- Start a new bounce or destroy the enemy when bounce finished.
enemy:register_event("on_jump_finished", function(enemy)

  bounce_count = bounce_count + 1
  if bounce_count < maximum_bounce then
    enemy:go()
  else
    sprite:set_animation("destroyed", function()
      enemy:remove()
    end)
  end
end)

-- Create an impact effect on hit.
enemy:register_event("on_hit", function(enemy)

  local x, y, _ = enemy:get_position()
  local offset_x, offset_y = sprite:get_xy()
  local hero_x, hero_y, _ = hero:get_position()
  enemy:start_brief_effect("entities/effects/impact_projectile", "default", (hero_x - x + offset_x) / 2, (hero_y - y + offset_y) / 2)
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  projectile_behavior.apply(enemy, sprite)
  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  sprite:set_animation("walking")
  enemy:set_damage(2)
  enemy:set_obstacle_behavior("flying")
  enemy:set_layer_independent_collisions(true)
  enemy:set_invincible()
  enemy:set_can_hurt_hero_running(true)
end)
