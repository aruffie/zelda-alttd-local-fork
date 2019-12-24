----------------------------------
--
-- Add basic projectile methods and events to an enemy.
--
-- Methods : enemy:remove_when_out_screen(movement)
--           enemy:straight_go([angle, [speed]])
--           enemy:bounce_go(bounce_duration, height, [angle, [speed, [callback]]])
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
  local default_bounce_duration = 600
  local default_bounce_height = 12
  

  -- Call the on_hit() callback and remove the entity if it doesn't return false.
  local function hit_behavior()

    if not enemy.on_hit or enemy:on_hit() ~= false then
      enemy:silent_kill()
    end
  end

  -- Remove the enemy when the given movement makes the enemy sprite completely out of the screen.
  function enemy:remove_when_out_screen(movement)

    function movement:on_position_changed()
      if not enemy:is_watched(sprite) then
        enemy:silent_kill()
      end
    end
  end

  -- Start going to the given angle, or to the hero if nil.
  function enemy:straight_go(angle, speed)

    local movement = sol.movement.create("straight")
    movement:set_angle(angle or enemy:get_angle(hero))
    movement:set_speed(speed or default_speed)
    movement:set_smooth(false)
    movement:start(enemy)
    sprite:set_direction(movement:get_direction4())

    function movement:on_obstacle_reached()
      hit_behavior()
    end

    return movement
  end

  -- Start bouncing to the given angle, or to the hero if nil.
  function enemy:bounce_go(duration, height, angle, speed, callback)
    return enemy:start_jumping(duration or default_bounce_duration, height or default_bounce_height, angle or enemy:get_angle(hero), speed or default_speed, callback)
  end

  -- Destroy the enemy when the hero is touched. 
  -- TODO adapt and move in the shield script for all enemy.
  enemy:register_event("on_attacking_hero", function(enemy, hero, enemy_sprite)

    if not hero:is_shield_protecting_from_enemy(enemy, enemy_sprite) or not game:has_item("shield") or game:get_item("shield"):get_variant() < enemy:get_minimum_shield_needed() then
      hero:start_hurt(enemy, enemy_sprite, enemy:get_damage())
    end
    hit_behavior()
  end)

  -- Destroy the enemy if needed when touching the shield.
  enemy:register_event("on_shield_collision", function(enemy, shield)
    hit_behavior()
  end)

  -- Hide the projectile when dying
  enemy:register_event("on_dying", function(enemy, shield)
    enemy:set_visible(false)
  end)
end

return behavior