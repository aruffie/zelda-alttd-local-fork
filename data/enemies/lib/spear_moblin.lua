----------------------------------
--
-- Add spear moblin behavior to an ennemy.
--
-- Usage : 
-- local my_enemy = ...
-- local behavior = require("enemies/lib/spear_moblin")
-- behavior.apply(my_enemy)
--
----------------------------------

-- Global variables
local behavior = {}
require("scripts/multi_events")

function behavior.apply(enemy)

  require("enemies/lib/common_actions").learn(enemy)
    
  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()
  local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  local quarter = math.pi * 0.5

  -- Configuration variables.
  local walking_possible_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
  local walking_speed = 48
  local walking_distance_grid = 16
  local walking_max_move_by_step = 2
  local waiting_duration = 800
  local throwing_animation_duration = 200

  -- Start the enemy movement.
  function enemy:start_walking(direction)

    enemy:start_straight_walking(walking_possible_angles[direction + 1], walking_speed, walking_distance_grid * math.random(walking_max_move_by_step), function()    
      local next_direction = math.random(4) - 1
      local waiting_animation = (direction + 1) % 4 == next_direction and "seek_left" or (direction - 1) % 4 == next_direction and "seek_right" or "immobilized"
      sprite:set_animation(waiting_animation)

      sol.timer.start(enemy, waiting_duration, function()

        -- Throw an arrow if the hero is on the direction the enemy is looking at.
        if enemy:get_direction4_to(hero) == sprite:get_direction() then
          enemy:throw_spear(function()
            enemy:start_walking(next_direction)
          end)
        else
          enemy:start_walking(next_direction)
        end
      end)
    end)
  end

  -- Throw a spear.
  function enemy:throw_spear(on_finished_callback)

    sprite:set_animation("throwing")
    sol.timer.start(enemy, throwing_animation_duration, function()
      local direction = sprite:get_direction()
      local x, y, layer = enemy:get_position()
      local spear = map:create_enemy({
        breed = "projectiles/spear",
        x = x,
        y = y,
        layer = layer,
        direction = direction
      })
      spear:get_sprite():set_xy(direction == 1 and 8 or direction == 3 and -8 or 0, direction % 2 == 0 and -11 or 0) -- Adapt the spear offset to moblins sprite.
      spear:go(direction * quarter) -- Reset the default move to go horizontally or vertically on the enemy direction.
      if on_finished_callback then
        on_finished_callback()
      end
    end)
  end

  -- Initialization.
  function enemy:on_created()
    enemy:set_life(2)
  end

  -- Restart settings.
  function enemy:on_restarted()

    -- Behavior for each items.
    enemy:set_attack_consequence("sword", 1)
    enemy:set_attack_consequence("thrown_item", 2)
    enemy:set_attack_consequence("hookshot", 2)
    enemy:set_attack_consequence("arrow", 2)
    enemy:set_attack_consequence("boomerang", 2)
    enemy:set_attack_consequence("explosion", 2)
    enemy:set_hammer_reaction(2)
    enemy:set_fire_reaction(2)

    -- States.
    enemy:set_can_attack(true)
    enemy:set_damage(1)
    enemy:start_walking(math.random(4) - 1)
  end
end

return behavior
