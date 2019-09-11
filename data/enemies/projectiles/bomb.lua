-- Lua script of enemy bomb, mainly used by the bomber and monkey enemies.

-- Global variables
local enemy = ...
local projectile_behavior = require("enemies/lib/projectile")

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local circle = 2.0 * math.pi
local bounce_count = 0
local throwing_angle
local shadow = nil

-- Configuration variables
local before_blinking_minimum_delay = 300
local before_blinking_maximum_delay = 1000
local before_explosing_delay = 1000
local bounce_height = 4
local bounce_speed = 40

-- Make the enemy bounce and go to a random target.
function enemy:go(duration, height, angle, speed)

  throwing_angle = angle or math.random() * circle
  enemy:bounce_go(duration, height, angle, speed)
  enemy:get_movement():set_ignore_obstacles(true)
end

-- Show or hide the enemy and its shadow.
function enemy:show(show)

  enemy:set_visible(show)
  if shadow then
    shadow:set_visible(show)
  end
end

-- Start a new bounce or destroy the enemy when bounce finished.
enemy:register_event("on_jump_finished", function(enemy)

  bounce_count = bounce_count + 1

  if bounce_count == 1 then
    sol.timer.start(enemy, math.random(before_blinking_minimum_delay, before_blinking_maximum_delay), function()
      sprite:set_animation("explosion_soon")
      sol.timer.start(enemy, before_explosing_delay, function()
        local x, y, layer = enemy:get_position()
        map:create_explosion({
          x = x,
          y = y,
          layer = layer
        })
        enemy:remove()
      end)
    end)
    enemy:go(nil, bounce_height, throwing_angle, bounce_speed)
  end
end)

-- Don't remove on hit.
enemy:register_event("on_hit", function(enemy)
  return false
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  projectile_behavior.apply(enemy, sprite)
  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  shadow = enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  sprite:set_animation("walking")
  enemy:set_damage(2)
  enemy:set_obstacle_behavior("flying")
  enemy:set_layer_independent_collisions(true)
  enemy:set_can_hurt_hero_running(true)
  enemy:set_invincible()
end)
