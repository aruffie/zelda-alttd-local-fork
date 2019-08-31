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
  require("enemies/lib/weapons").learn(enemy)
    
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
          local x_offset = direction == 1 and 8 or direction == 3 and -8 or 0 -- Adapt the spear projectile offset to moblins sprite.
          local y_offset = direction % 2 == 0 and -11 or 0
          enemy:throw_projectile("spear", throwing_animation_duration, true, x_offset, y_offset, function()
            enemy:start_walking(next_direction)
          end)
        else
          enemy:start_walking(next_direction)
        end
      end)
    end)
  end

  -- Initialization.
  enemy:register_event("on_created", function(enemy)

    enemy:set_life(2)
    enemy:set_size(16, 16)
    enemy:set_origin(8, 13)
  end)

  -- Restart settings.
  enemy:register_event("on_restarted", function(enemy)

    -- Behavior for each items.
    enemy:set_hero_weapons_reactions(2, {
      sword = 1, 
      jump_on = "ignored"})

    -- States.
    enemy:set_can_attack(true)
    enemy:set_damage(1)
    enemy:start_walking(math.random(4) - 1)
  end)
end

return behavior
