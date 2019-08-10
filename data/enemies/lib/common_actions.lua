----------------------------------
--
-- Add some basic and common methods/events to an enemy.
--
-- Methods : enemy:is_near(entity, triggering_distance)
--           enemy:start_random_walking(possible_angles, speed, distance, sprite, on_finished_callback)
--           enemy:start_walking_to(hero, speed, sprite)
--           enemy:start_attracting(entity, pixel_by_second, reverse_move, moving_condition_callback)
--           enemy:stop_attracting()
--           enemy:steal_item(item_name, variant, only_if_assigned)
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

  local trigonometric_functions = {math.cos, math.sin}
  local is_attracting = false

  -- Return true if the entity is closer to the enemy than triggering_distance
  function enemy:is_near(entity, triggering_distance)

    local _, _, layer = enemy:get_position()
    local _, _, entity_layer = entity:get_position()
    return (layer == entity_layer or enemy:has_layer_independent_collisions()) and enemy:get_distance(entity) < triggering_distance
  end

  -- Make the enemy straight move randomly over one of the given angle.
  function enemy:start_random_walking(possible_angles, speed, distance, sprite, on_finished_callback)

    math.randomseed(sol.main.get_elapsed_time())
    local direction = math.random(#possible_angles)
    local movement = sol.movement.create("straight")
    movement:set_speed(speed)
    movement:set_max_distance(distance)
    movement:set_angle(possible_angles[direction])
    movement:set_smooth(true)
    movement:start(self)

    sprite:set_animation("walking")
    sprite:set_direction(movement:get_direction4())

    function movement:on_finished()
      if on_finished_callback then
        on_finished_callback()
      end
    end

    -- Consider the current move as finished if stuck.
    function movement:on_obstacle_reached()
      movement:stop()
      if on_finished_callback then
        on_finished_callback()
      end
    end

    return movement
  end

  -- Make the enemy move to the entity.
  function enemy:start_walking_to(entity, speed, sprite)

    local movement = sol.movement.create("target")
    movement:set_speed(speed)
    movement:set_target(entity)
    movement:start(enemy)
    sprite:set_animation("walking")

    return movement
  end

  -- Start attracting the given entity by pixel_by_second, or expulse if reverse_move is set.
  function enemy:start_attracting(entity, pixel_by_second, reverse_move, moving_condition_callback)

    local move_ratio = reverse_move and -1 or 1
    is_attracting = true

    local function attract_on_axis(axis)

      local entity_position = {entity:get_position()}
      local enemy_position = {enemy:get_position()}
      local angle = math.atan2(entity_position[2] - enemy_position[2], enemy_position[1] - entity_position[1])
      
      local axis_move = {0, 0}
      local axis_move_delay = 10 -- Default timer delay if no move

      if not moving_condition_callback or moving_condition_callback() then

        -- Always move pixel by pixel.
        axis_move[axis] = math.max(math.min(enemy_position[axis] - entity_position[axis], 1), -1) * move_ratio
        if axis_move[axis] ~= 0 then

          -- Schedule the next move on this axis depending on the remaining distance and the pixel_by_second value.
          axis_move_delay = math.abs(1000.0 / (pixel_by_second * trigonometric_functions[axis](angle)))

          -- Move the hero.
          if not entity:test_obstacles(axis_move[1], axis_move[2]) then
            entity:set_position(entity_position[1] + axis_move[1], entity_position[2] + axis_move[2], entity_position[3])
          end
        end

        -- Avoid too short timers.
        if axis_move_delay < 10 then
          axis_move_delay = 10
        end
      end

      -- Start the next move timer.
      if is_attracting then
        sol.timer.start(enemy, axis_move_delay, function()
          attract_on_axis(axis)
        end)
      end
    end

    attract_on_axis(1)
    attract_on_axis(2)
  end

  -- Stop looped timers related to the attractions.
  function enemy:stop_attracting()
    is_attracting = false
  end

  -- Steal an item and drop it when died, possibly conditionned on the variant and the assignation to a slot.
  function enemy:steal_item(item_name, variant, only_if_assigned)

    if game:has_item(item_name) then
      local item = game:get_item(item_name)
      local item_slot = (game:get_item_assigned(1) == item and 1) or (game:get_item_assigned(2) == item and 2) or nil

      if (not variant or item:get_variant() == variant) and (not only_if_assigned or item_slot) then     
        enemy:set_treasure(item_name, item:get_variant()) -- TODO savegame variable
        item:set_variant(0)
        if item_slot then
          game:set_item_assigned(item_slot, nil)
        end
      end
    end
  end
end

return common_actions