----------------------------------
--
-- Add zol behavior to an ennemy.
--
-- Usage : 
-- local my_enemy = ...
-- local behavior = require("enemies/lib/zol")
-- behavior.apply(my_enemy)
--
----------------------------------

-- Global variables
local behavior = {}
local common_actions = require("enemies/lib/common_actions")
require("scripts/multi_events")

function behavior.apply(enemy, properties)

  local map = enemy:get_map()
  local hero = map:get_hero()
  local sprite = properties.sprite

  -- Configuration variables
  local walking_speed = properties.walking_speed or 4
  local jumping_speed = properties.jumping_speed or 64
  local jumping_height = properties.jumping_height or 12
  local jumping_duration = properties.jumping_duration or 600
  local attack_triggering_distance = properties.attack_triggering_distance or 64
  local shaking_duration = properties.shaking_duration or 1000
  local exhausted_duration = properties.exhausted_duration or 2000
  local exhausted_maximum_extra_duration = properties.exhausted_maximum_extra_duration or 2000

  -- Initialization
  common_actions.learn(enemy, sprite)
  enemy:set_life(1)
  enemy:add_shadow()

  -- Start moving to the hero, and jump when he is close enough.
  function enemy:start_walking()
    
    local movement = enemy:start_target_walking(hero, walking_speed)
    function movement:on_position_changed()
      if not enemy.is_attacking and not enemy.is_exhausted and enemy:is_near(hero, attack_triggering_distance) then
        enemy.is_attacking = true
        movement:stop()
        
        -- Shake for a short duration then start attacking.
        sprite:set_animation("shaking")
        sol.timer.start(enemy, shaking_duration, function()
           enemy:start_jump_attack(true)
        end)
      end
    end
  end

  -- Event triggered when the enemy is close enough to the hero.
  function enemy:start_jump_attack(offensive)

    -- Start jumping to the hero.
    enemy:start_jumping_movement(offensive)
    enemy:start_jumping(jumping_duration, false, jumping_height)
  end

  -- Make the enemy move to or away to the hero.
  function enemy:start_jumping_movement(offensive)

    -- Start the on-floor jumping movement.
    local hero_x, hero_y, _ = hero:get_position()
    local enemy_x, enemy_y, _ = enemy:get_position()
    local movement = sol.movement.create("straight")
    movement:set_speed(jumping_speed)
    movement:set_angle(math.atan2(hero_y - enemy_y, enemy_x - hero_x) + (offensive and math.pi or 0))
    movement:set_max_distance(jumping_speed * 0.001 * jumping_duration)
    movement:set_smooth(false)
    movement:start(enemy)
    sprite:set_animation("jump")
  end

  -- Stop being exhausted after a minimum delay + random time
  function enemy:schedule_exhausted_end()

    math.randomseed(sol.main.get_elapsed_time())
    sol.timer.start(enemy, exhausted_duration + math.random(exhausted_maximum_extra_duration), function()
      enemy.is_exhausted = false
    end)
  end

  -- Start walking again when the attack finished.
  enemy:register_event("on_jump_finished", function(enemy)
    enemy:restart()
  end)

  -- Restart settings.
  enemy:register_event("on_restarted", function(enemy)

    -- States.
    enemy.is_attacking = false
    enemy.is_exhausted = true
    enemy:schedule_exhausted_end()
    enemy:start_walking()
  end)
end

return behavior
