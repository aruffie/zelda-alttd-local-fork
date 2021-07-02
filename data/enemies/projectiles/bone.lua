-- Bone projectile, mainly used by the red Stalfos enemy.

local enemy = ...
local projectile_behavior = require("enemies/lib/projectile")

-- Global variables
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())

-- Remove the projectile on shield collision.
local function on_shield_collision()

  enemy:on_hit()
  enemy:start_death()
end

-- Immediately die on hurt.
local function on_hurt()

  enemy:start_death(function()
    local sprite_x, sprite_y = sprite:get_xy()
    enemy:set_visible(false)
    enemy:start_brief_effect("enemies/enemy_killed", nil, sprite_x, sprite_y, nil, function()
      finish_death()
    end)
  end)
end

-- Start going to the hero.
function enemy:go()
  enemy:straight_go()
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

  enemy:set_hero_weapons_reactions({
    arrow = "ignored",
  	boomerang = "ignored",
  	explosion = "ignored",
  	sword = on_hurt,
  	thrown_item = "ignored",
  	fire = "ignored",
  	jump_on = "ignored",
  	hammer = on_hurt,
  	hookshot = on_hurt,
  	magic_powder = "ignored",
  	shield = on_shield_collision,
  	thrust = on_attack_received
  })

  sprite:set_animation("walking")
  enemy:set_damage(2)
  enemy:set_obstacle_behavior("flying")
  enemy:set_pushed_back_when_hurt(false)
  enemy:go()
end)
