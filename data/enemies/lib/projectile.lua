----------------------------------
--
-- Add projectile behavior to an ennemy.
--
-- Methods : enemy:go()
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

  -- Start going to the hero
  function enemy:go()

    local movement = sol.movement.create("straight")
    movement:set_speed(192)
    movement:set_angle(enemy:get_angle(hero))
    movement:set_smooth(false)

    function movement:on_obstacle_reached()
      enemy:remove()
    end

    movement:start(enemy)
  end

  -- Destroy the enemy when the hero is touched.
  function enemy:on_attacking_hero(hero, enemy_sprite)
    -- Don't hurt if the shield is protecting.
    if not hero:is_shield_protecting_from_enemy(enemy, enemy_sprite) or not game:has_item("shield") or game:get_item("shield"):get_variant() < enemy:get_minimum_shield_needed() then
      hero:start_hurt(enemy, enemy_sprite, enemy:get_damage())
    end
    enemy:remove()
  end

  -- Destroy the enemy if needed when touching the shield.
  function enemy:on_shield_collision(shield)
    enemy:remove()
  end
end

return behavior