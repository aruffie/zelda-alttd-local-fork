----------------------------------
--
-- Add some basic and common methods/events to an enemy.
--
-- Methods : enemy:is_near(entity, triggering_distance)
--           enemy:start_random_walking(possible_angles, speed, distance, on_finished_callback)
--           enemy:start_target_walking(entity, speed)
--           enemy:start_jumping(duration, unsensitive, height)
--           enemy:start_flying(take_off_duration, unsensitive, height)
--           enemy:stop_flying(landing_duration)
--           enemy:start_attracting(entity, pixel_by_second, reverse_move, moving_condition_callback)
--           enemy:stop_attracting()
--           enemy:steal_item(item_name, variant, only_if_assigned)
--           enemy:add_shadow()
-- Events:   enemy:on_jump_finished()
--           enemy:on_fly_took_off()
--           enemy:on_fly_landed()
--
-- Usage : 
-- local my_enemy = ...
-- local common_actions = require("enemies/lib/common_actions")
-- local main_sprite = enemy:create_sprite("my_enemy_main_sprite")
-- common_actions.learn(my_enemy, main_sprite)
--
----------------------------------

local common_actions = {}

function common_actions.learn(enemy, main_sprite) -- Workaround. The solarus notion of main enemy sprite is not really reliable, pass it explicitely at creation.

  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()
  local trigonometric_functions = {math.cos, math.sin}

  local attracting_timers = {}
  
  -- Return true if the entity is closer to the enemy than triggering_distance
  function enemy:is_near(entity, triggering_distance)

    local _, _, layer = enemy:get_position()
    local _, _, entity_layer = entity:get_position()
    return (layer == entity_layer or enemy:has_layer_independent_collisions()) and enemy:get_distance(entity) < triggering_distance
  end

  -- Make the enemy straight move randomly over one of the given angle.
  function enemy:start_random_walking(possible_angles, speed, distance, on_finished_callback)

    math.randomseed(sol.main.get_elapsed_time())
    local direction = math.random(#possible_angles)
    local movement = sol.movement.create("straight")
    movement:set_speed(speed)
    movement:set_max_distance(distance)
    movement:set_angle(possible_angles[direction])
    movement:set_smooth(true)
    movement:start(self)

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

    -- Update the main sprite.
    if main_sprite:has_animation("walking") then
      main_sprite:set_animation("walking")
    end
    main_sprite:set_direction(movement:get_direction4())

    return movement
  end

  -- Make the enemy move to the entity.
  function enemy:start_target_walking(entity, speed)

    local movement = sol.movement.create("target")
    movement:set_speed(speed)
    movement:set_target(entity)
    movement:start(enemy)

    -- Update the main sprite.
    if main_sprite:has_animation("walking") then
      main_sprite:set_animation("walking")
    end
    main_sprite:set_direction(movement:get_direction4())

    return movement
  end

  -- Make the enemy start jumping.
  function enemy:start_jumping(duration, unsensitive, height)

    -- Make enemy unable to interact with the hero if requested.
    if unsensitive then
      enemy:set_invincible()
      enemy:set_can_attack(false)
      enemy:set_damage(0)
    end

    -- Update the sprite vertical offset at each frame.
    local elapsed_time = 0

    local function update_sprite_height()
      if elapsed_time < duration then
        main_sprite:set_xy(0, -math.sqrt(math.sin(elapsed_time / duration * math.pi)) * height)
        sol.timer.start(enemy, 10, function()
          elapsed_time = elapsed_time + 10
          update_sprite_height()
        end)
      else
        main_sprite:set_xy(0, 0)

        -- Call enemy:on_jump_finished() event.
        if enemy.on_jump_finished then
          enemy:on_jump_finished()
        end
      end
    end
    update_sprite_height()
  end

  -- Make the enemy start flying.
  function enemy:start_flying(take_off_duration, unsensitive, height)

    -- Make enemy unable to interact with the hero if requested.
    if unsensitive then
      enemy:set_invincible()
      enemy:set_can_attack(false)
      enemy:set_damage(0)
    end

    -- Make the main sprite start elevating.
    local movement = sol.movement.create("straight")
    movement:set_speed(height * 1000 / take_off_duration)
    movement:set_max_distance(height)
    movement:set_angle(math.pi * 0.5)
    movement:set_ignore_obstacles(true)
    movement:start(main_sprite)

    -- Call the enemy:on_fly_took_off() method once take off finished.
    function movement:on_finished()
      if enemy.on_fly_took_off then
        enemy:on_fly_took_off()
      end
    end
  end

  -- Make the enemy stop flying.
  function enemy:stop_flying(landing_duration)

    -- Make the main sprite start landing.
    local _, height = main_sprite:get_xy()
    height = math.abs(height)
    local movement = sol.movement.create("straight")
    movement:set_speed(height * 1000 / landing_duration)
    movement:set_max_distance(height)
    movement:set_angle(-math.pi * 0.5)
    movement:set_ignore_obstacles(true)
    movement:start(main_sprite)

    -- Call the enemy:on_fly_landed() method once landed finished.
    function movement:on_finished()
      if enemy.on_fly_landed then
        enemy:on_fly_landed()
      end
    end
  end

  -- Start attracting the given entity by pixel_by_second, or expulse it if reverse_move is set.
  function enemy:start_attracting(entity, pixel_by_second, reverse_move, moving_condition_callback)

    local move_ratio = reverse_move and -1 or 1
    attracting_timers[entity] = {}

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

          -- Schedule the next move on this axis depending on the remaining distance and the pixel_by_second value, avoiding too high and low timers.
          axis_move_delay = 1000.0 / math.max(1, math.min(100, math.abs(pixel_by_second * trigonometric_functions[axis](angle))))

          -- Move the entity.
          if not entity:test_obstacles(axis_move[1], axis_move[2]) then
            entity:set_position(entity_position[1] + axis_move[1], entity_position[2] + axis_move[2], entity_position[3])
          end
        end
      end

      -- Start the next move timer.
      attracting_timers[entity][axis] = sol.timer.start(enemy, axis_move_delay, function()
        attract_on_axis(axis)
      end)
    end

    attract_on_axis(1)
    attract_on_axis(2)
  end

  -- Stop looped timers related to the attractions.
  function enemy:stop_attracting()

    for _, timers in pairs(attracting_timers) do
      if timers then
        for i = 1, 2 do
          if timers[i] then
            timers[i]:stop()
          end
        end
      end
    end
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

  -- Add a shadow below the enemy.
  function enemy:add_shadow()

    local shadow_sprite = enemy:create_sprite("entities/shadows/shadow", "shadow")
    enemy:bring_sprite_to_back(shadow_sprite)

    -- Make shadow sprite unable to interact with the hero.
    enemy:set_attack_consequence_sprite(shadow_sprite, "sword", "ignored")
    enemy:set_attack_consequence_sprite(shadow_sprite, "thrown_item", "ignored")
    enemy:set_attack_consequence_sprite(shadow_sprite, "explosion", "ignored")
    enemy:set_attack_consequence_sprite(shadow_sprite, "arrow", "ignored")
    enemy:set_attack_consequence_sprite(shadow_sprite, "hookshot", "ignored")
    enemy:set_attack_consequence_sprite(shadow_sprite, "boomerang", "ignored")
    enemy:set_attack_consequence_sprite(shadow_sprite, "fire", "ignored")
    function enemy:on_attacking_hero(hero, enemy_sprite)
      if enemy_sprite ~= shadow_sprite then
        hero:start_hurt(enemy, enemy:get_damage())
      end
    end
  end
end

return common_actions