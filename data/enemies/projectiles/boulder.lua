-- Lua script of boulder projectile.

-- Global variables
local enemy = ...
local projectile_behavior = require("enemies/lib/projectile")

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local is_hitting = false

-- Configuration variables
local minimum_speed = 40
local maximum_speed = 80

-- Make the enemy bounce and go to a random target at the south the enemy.
function enemy:go()
  enemy:bounce_go(math.pi + math.random() * math.pi, math.random(minimum_speed, maximum_speed))
  enemy:get_movement():set_ignore_obstacles(true)
end

-- Start a new bounce when finished.
enemy:register_event("on_jump_finished", function(enemy)
  enemy:go()
end)

-- Remove enemy if moving and out of the screen.
enemy:register_event("on_position_changed", function(enemy)
  if enemy:get_movement() and not enemy:overlaps(map:get_camera()) then
    enemy:remove()
  end
end)

-- Create an impact effect on hit.
enemy:register_event("on_hit", function(enemy)

  if not is_hitting then
    is_hitting = true -- Avoid creating many impacts when using the shield.

    local x, y, _ = enemy:get_position()
    local offset_x, offset_y = sprite:get_xy()
    local hero_x, hero_y, _ = hero:get_position()
    enemy:start_brief_effect("entities/effects/impact_projectile", "default", (hero_x - x + offset_x) / 2, (hero_y - y + offset_y) / 2, nil, function()
      is_hitting = false
    end)
  end

  return false
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  projectile_behavior.apply(enemy, sprite)
  enemy:set_life(1)
  enemy:set_size(32, 32)
  enemy:set_origin(16, 29)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  is_hitting = false
  sprite:set_animation("normal")
  enemy:set_damage(2)
  enemy:set_obstacle_behavior("flying")
  enemy:set_layer_independent_collisions(true)
  enemy:set_invincible()
  enemy:set_can_hurt_hero_running(true)
  enemy:go()
end)
