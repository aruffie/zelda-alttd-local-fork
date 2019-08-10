----------------------------------
--
-- Add stalfos behavior to an ennemy.
--
-- Methods : enemy:start_walking()
--           enemy:jump(target_x, target_y)
-- Events :  enemy:on_attacking()
--
-- Usage : 
-- local my_enemy = ...
-- local behavior = require("enemies/lib/stalfos")
-- behavior.apply(my_enemy)
----------------------------------

-- Global variables
local behavior = {}
local common_actions = require("enemies/lib/common_actions")

-- Configuration variables
local walking_speed = 32
local jumping_speed = 128
local attack_triggering_distance = 48

function behavior.apply(enemy)

  common_actions.learn(enemy)

  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()
  local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())

  -- Start moving to the hero.
  function enemy:start_walking()

    local movement = enemy:start_target_walking(hero, walking_speed, sprite)
    function movement:on_position_changed()
      if enemy:is_near(hero, attack_triggering_distance) then
        movement:stop()
        if enemy.on_attacking() then
          enemy:on_attacking()
        end
      end
    end
  end

  -- Make the enemy jump on the given target.
  function enemy:start_jumping(target_x, target_y)

    -- Start jumping and stomp down on the current hero position.
    local movement = sol.movement.create("target")
    movement:set_speed(jumping_speed)
    movement:set_target(target_x, target_y)
    movement:start(enemy)
    sprite:set_animation("jumping")
  end

  -- Initialization.
  function enemy:on_created()

    -- Game properties.
    enemy:set_life(3)
    enemy:set_damage(1)
    
    -- Behavior for each items.
    enemy:set_attack_consequence("sword", 1)
    enemy:set_attack_consequence("thrown_item", 2)
    enemy:set_attack_consequence("arrow", 2)
    enemy:set_attack_consequence("hookshot", 2)
    enemy:set_attack_consequence("fire", 2)
    enemy:set_attack_consequence("boomerang", 2)
    enemy:set_attack_consequence("explosion", 2)
    enemy:set_hammer_reaction(2)
  end

  -- Initial movement.
  function enemy:on_restarted()

    enemy:start_walking()
  end
end

return behavior
