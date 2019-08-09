----------------------------------
--
-- Add some basic and common methods/events to an enemy.
--
-- Methods : enemy:start_random_walking(possible_angles, walking_speed, walking_distance, sprite)
--           enemy:attract_hero(distance)
--           enemy:steal_item(item_name, variant, only_if_assigned)
-- Events :  enemy:on_random_walk_finished()
--
-- Usage : 
-- local my_enemy = ...
-- local common_actions = require("enemies/lib/common_actions")
-- common_actions.learn(my_enemy)
----------------------------------

local common_actions = {}

function common_actions.learn(enemy)

  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()

  -- Make the enemy straight move randomly over one of the given angle.
  function enemy:start_random_walking(possible_angles, walking_speed, walking_distance, sprite)

    math.randomseed(sol.main.get_elapsed_time())
    local direction = math.random(#possible_angles)
    local movement = sol.movement.create("straight")
    movement:set_speed(walking_speed)
    movement:set_max_distance(walking_distance)
    movement:set_angle(possible_angles[direction])
    movement:set_smooth(true)
    movement:start(self)

    sprite:set_animation("walking")
    sprite:set_direction(movement:get_direction4())

    function movement:on_finished()
      if enemy.on_random_walk_finished then
        enemy:on_random_walk_finished()
      end
    end

    -- Consider the current move as finished if stuck.
    function movement:on_obstacle_reached()
      movement:stop()
      if enemy.on_random_walk_finished then
        enemy:on_random_walk_finished()
      end
    end
  end

  -- Attract the hero by one pixel on each axis, repulse possible by passing a negative number.
  function enemy:attract_hero(distance)

    local hero_x, hero_y, hero_layer = hero:get_position()
    local enemy_x, enemy_y, enemy_layer = enemy:get_position()
    local move_x = math.max(math.min(enemy_x - hero_x, 1), -1) * distance
    local move_y = math.max(math.min(enemy_y - hero_y, 1), -1) * distance

    -- Do one step by axis to simulate a smooth movement.
    if hero:test_obstacles(move_x, 0) then
      move_x = 0
    end
    if hero:test_obstacles(move_x, move_y) then
      move_y = 0
    end
    hero:set_position(hero_x + move_x, hero_y + move_y, hero_layer)
  end

  -- Steal an item and drop it when died, possibility conditionned on the variant and the assignation to a slot.
  function enemy:steal_item(item_name, variant, only_if_assigned)

    if game:has_item(item_name) then
      local item = game:get_item(item_name)
      local item_slot = (game:get_item_assigned(1) == item and 1) or (game:get_item_assigned(2) == item and 2) or nil

      if (not variant or item:get_variant() == variant) and (not only_if_assigned or item_slot) then     
        enemy:set_treasure(item_name, item:get_variant())
        item:set_variant(0)
        if item_slot then
          game:set_item_assigned(item_slot, nil)
        end
      end
    end
  end
end

return common_actions