-- Lua script of boulder projectile.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()

-- Configuration variables
local bounce_duration = 600
local bounce_height = 12
local minimum_speed = 40
local maximum_speed = 80

-- Make the enemy bounce and go to a random target at the south the enemy.
function enemy:bounce()

  local movement = enemy:start_jumping(bounce_duration, bounce_height, math.pi + math.random() * math.pi, math.random(minimum_speed, maximum_speed))
  movement:set_ignore_obstacles(true)
end

-- Start a new bounce when jump finished.
enemy:register_event("on_jump_finished", function(enemy)
  enemy:bounce()
end)

-- Create an impact effect on hurt hero.
-- TODO register_event() seems to not prevent the default behavior, check how to use it.
function enemy:on_attacking_hero(hero, enemy_sprite)

  local x, y, _ = enemy:get_position()
  local offset_x, offset_y = sprite:get_xy()
  local hero_x, hero_y, _ = hero:get_position()
  enemy:start_brief_effect("entities/effects/impact_projectile", "default", (hero_x - x + offset_x) / 2, (hero_y - y + offset_y) / 2)
  hero:start_hurt(enemy, enemy_sprite, enemy:get_damage())
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(32, 32)
  enemy:set_origin(16, 29)
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
  enemy:bounce()
end)
