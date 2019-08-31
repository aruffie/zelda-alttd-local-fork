----------------------------------
--
-- Add projectile behavior to an ennemy.
--
-- Methods : enemy:set_default_speed(speed)
--           enemy:go([angle, [speed]])
-- Events :  enemy:on_hit()
--
-- Usage : 
-- local my_enemy = ...
-- local behavior = require("enemies/lib/projectile")
-- local main_sprite = enemy:create_sprite("my_enemy_main_sprite")
-- behavior.apply(my_enemy, main_sprite)
--
----------------------------------

local behavior = {}

function behavior.apply(enemy, sprite)

  require("enemies/lib/common_actions").learn(enemy)
  local audio_manager = require("scripts/audio_manager")

  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()

  local default_speed = 192

  -- Call the on_hit() callback or remove the entity if not set on hit.
  function enemy:hit_behavior()

    local handled = false
    if enemy.on_hit then
      handled = enemy:on_hit()
    end
    if not handled then
      enemy:remove()
    end
  end

  -- Set a projectile speed.
  function enemy:set_default_speed(speed)
    default_speed = speed
  end

  -- Start going to the given angle, or to the hero if nil.
  function enemy:go(angle, speed)

    local movement = sol.movement.create("straight")
    movement:set_angle(angle or enemy:get_angle(hero))
    movement:set_speed(speed or default_speed)
    movement:set_smooth(false)
    movement:start(enemy)
    sprite:set_direction(movement:get_direction4())

    function movement:on_obstacle_reached()
      enemy:hit_behavior()
    end
  end

  -- Destroy the enemy when the hero is touched. 
  -- TODO adapt and move in the shield script for all enemy.
  enemy:register_event("on_attacking_hero", function(enemy, hero, enemy_sprite)
    -- Don't hurt if the shield is protecting.
    if not hero:is_shield_protecting_from_enemy(enemy, enemy_sprite) or not game:has_item("shield") or game:get_item("shield"):get_variant() < enemy:get_minimum_shield_needed() then
      hero:start_hurt(enemy, enemy_sprite, enemy:get_damage())
    end
    enemy:hit_behavior()
  end)

  -- Destroy the enemy if needed when touching the shield.
  enemy:register_event("on_shield_collision", function(enemy, shield)
    enemy:hit_behavior()
  end)
end

return behavior