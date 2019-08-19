----------------------------------
--
-- Add projectile behavior to an ennemy.
--
-- Methods : enemy:go()
-- Events :  enemy:on_hit()
--
-- Usage : 
-- local my_enemy = ...
-- local behavior = require("enemies/lib/projectile")
-- behavior.apply(my_enemy)
--
----------------------------------

local behavior = {}

function behavior.apply(enemy)

  local audio_manager = require("scripts/audio_manager")

  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()

  local default_speed = 192

  -- Call the on_hit() callback or remove the entity if not set on hit.
  function enemy:hit_behavior()

    if enemy.on_hit then
      enemy:on_hit()
    else
      enemy:remove()
    end
  end

  -- Set a projectile speed.
  function enemy:set_speed(speed)
    default_speed = speed
  end

  -- Start going to the hero
  function enemy:go(angle, speed)

    local movement = sol.movement.create("straight")
    movement:set_angle(angle or enemy:get_angle(hero))
    movement:set_speed(speed or default_speed)
    movement:set_smooth(false)

    function movement:on_obstacle_reached()
      enemy:hit_behavior()
    end

    movement:start(enemy)
  end

  -- Destroy the enemy when the hero is touched. 
  -- TODO adapt and move in the shield script for all enemy.
  function enemy:on_attacking_hero(hero, enemy_sprite)
    -- Don't hurt if the shield is protecting.
    if not hero:is_shield_protecting_from_enemy(enemy, enemy_sprite) or not game:has_item("shield") or game:get_item("shield"):get_variant() < enemy:get_minimum_shield_needed() then
      hero:start_hurt(enemy, enemy_sprite, enemy:get_damage())
    end
    enemy:hit_behavior()
  end

  -- Destroy the enemy if needed when touching the shield.
  function enemy:on_shield_collision(shield)
    enemy:hit_behavior()
  end
end

return behavior