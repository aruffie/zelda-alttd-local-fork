----------------------------------
--
-- Add some basic methods to an enemy.
-- There is no passive behavior without an explicit start when learning this to an enemy.
--
-- Methods : General informations :
--           enemy:is_aligned(entity, thickness, [sprite])
--           enemy:is_near(entity, triggering_distance, [sprite])
--           enemy:is_entity_in_front(entity, [front_angle, [sprite]])
--           enemy:is_leashed_by(entity)
--           enemy:is_over_grounds(grounds)
--           enemy:is_watched([sprite, [fully_visible]])
--           enemy:get_central_symmetry_position(x, y)
--           enemy:get_obstacles_normal_angle()
--           enemy:get_obstacles_bounce_angle([angle])
--
--           Movements and positioning :
--           enemy:start_straight_walking(angle, speed, [distance, [on_stopped_callback]])
--           enemy:start_target_walking(entity, speed)
--           enemy:start_jumping(duration, height, [angle, speed, [on_finished_callback]])
--           enemy:start_flying(take_off_duration, height, [on_finished_callback])
--           enemy:stop_flying(landing_duration, [on_finished_callback])
--           enemy:start_attracting(entity, speed, [moving_condition_callback])
--           enemy:stop_attracting([entity])
--           enemy:start_impulsion(x, y, speed, acceleration, deceleration)
--           enemy:start_throwing(entity, duration, start_height, [maximum_height, [angle, speed, [on_finished_callback]]])
--           enemy:start_welding(entity, [x, [y]])
--           enemy:start_leashed_by(entity, maximum_distance)
--           enemy:stop_leashed_by(entity)
--           enemy:start_pushed_back(entity, [speed, [duration, [on_finished_callback]]])
--           enemy:start_pushing_back(entity, [speed, [duration, [on_finished_callback]]])
--           enemy:start_shock(entity, [speed, [duration, [on_finished_callback]]])
--
--           Effects and events :
--           enemy:start_death([dying_callback])
--           enemy:start_shadow([sprite_name, [animation_name, [x, [y]]]])
--           enemy:start_brief_effect(sprite_name, [animation_name, [x, [y, [maximum_duration, [on_finished_callback]]]]])
--           enemy:start_close_explosions(maximum_distance, duration, [explosion_sprite_name, [x, [y, [on_finished_callback]]]])
--           enemy:start_sprite_explosions([sprites, [explosion_sprite_name, [x, [y, [on_finished_callback]]]]])
--           enemy:stop_all()
--
-- Usage : 
-- local my_enemy = ...
-- local common_actions = require("enemies/lib/common_actions")
-- common_actions.learn(my_enemy)
--
----------------------------------

local common_actions = {}

function common_actions.learn(enemy)

  local game = enemy:get_game()
  local map = enemy:get_map()
  local hero = map:get_hero()
  local camera = map:get_camera()
  local trigonometric_functions = {math.cos, math.sin}
  local circle = 2.0 * math.pi
  local quarter = 0.5 * math.pi
  local eighth = 0.25 * math.pi

  local attracting_timers = {}
  local leashing_timers = {}
  local shadow = nil
  
  local function xor(a, b)
    return (a or b) and not (a and b)
  end

  -- Return true if the entity is on the same row or column than the entity.
  function enemy:is_aligned(entity, thickness, sprite)

    local half_thickness = thickness * 0.5
    local entity_x, entity_y, entity_layer = entity:get_position()
    local x, y, layer = enemy:get_position()
    if sprite then
      local x_offset, y_offset = sprite:get_xy()
      x, y = x + x_offset, y + y_offset
    end

    return (math.abs(entity_x - x) < half_thickness or math.abs(entity_y - y) < half_thickness)
      and (layer == entity_layer or enemy:has_layer_independent_collisions())
  end

  -- Return true if the entity is closer to the enemy than triggering_distance
  function enemy:is_near(entity, triggering_distance, sprite)

    local entity_layer = entity:get_layer()
    local x, y, layer = enemy:get_position()
    if sprite then
      local x_offset, y_offset = sprite:get_xy()
      x, y = x + x_offset, y + y_offset
    end

    return entity:get_distance(x, y) < triggering_distance 
      and (layer == entity_layer or enemy:has_layer_independent_collisions())
  end

  -- Return true if the angle between the enemy sprite direction and the enemy to entity direction is less than or equals to the front_angle.
  function enemy:is_entity_in_front(entity, front_angle, sprite)

    front_angle = front_angle or math.pi / 2.0
    sprite = sprite or enemy:get_sprite()

    -- Check the difference on the cosinus axis to easily consider angles from enemy to hero like pi and 3pi as the same.
    return math.cos(math.abs(sprite:get_direction() * math.pi / 2.0 - enemy:get_angle(entity))) >= math.cos(front_angle / 2.0)
  end

  -- Return true if the enemy is currently leashed by the entity with enemy:start_leashed_by().
  function enemy:is_leashed_by(entity)
    return leashing_timers[entity] ~= nil
  end

  -- Return true if the four corners of the enemy are over one of the given ground, not necessarily the same.
  function enemy:is_over_grounds(grounds)

    local x, y, layer = enemy:get_position()
    local width, height = enemy:get_size()
    local origin_x, origin_y = enemy:get_origin()
    x, y = x - origin_x, y - origin_y

    local function is_position_over_grounds(x, y)
      for _, ground in pairs(grounds) do
        if string.find(map:get_ground(x, y, layer), ground) then
          return true
        end
      end
      return false
    end

    return is_position_over_grounds(x, y)
        and is_position_over_grounds(x + width - 1, y)
        and is_position_over_grounds(x, y + height - 1)
        and is_position_over_grounds(x + width - 1, y + height - 1)
  end

  -- Return true if the enemy or its given sprite is partially visible at the camera, or fully visible if requested.
  function enemy:is_watched(sprite, fully_visible)

    local camera_x, camera_y = camera:get_position()
    local camera_width, camera_height = camera:get_size()
    local target = sprite or enemy
    local x, y, _ = enemy:get_position()
    local width, height = target:get_size()
    local origin_x, origin_y = target:get_origin()
    x, y = x - origin_x, y - origin_y

    if sprite then
      local offset_x, offset_y = sprite:get_xy()
      x, y = x + offset_x, y + offset_y
    end

    if fully_visible then
      x, y = x + width, y + height
      width, height = -width, -height
    end

    return x + width >= camera_x and x <= camera_x + camera_width 
        and y + height >= camera_y and y <= camera_y + camera_height
  end

  -- Return the central symmetry position over the given central point.
  function enemy:get_central_symmetry_position(x, y)

    local enemy_x, enemy_y, _ = enemy:get_position()
    return 2.0 * x - enemy_x, 2.0 * y - enemy_y
  end

  -- Return the normal angle of close obstacles as a multiple of pi/4, or nil if none.
  function enemy:get_obstacles_normal_angle()

    local collisions = {
      [0] = enemy:test_obstacles(-1,  0),
      [1] = enemy:test_obstacles(-1,  1),
      [2] = enemy:test_obstacles( 0,  1),
      [3] = enemy:test_obstacles( 1,  1),
      [4] = enemy:test_obstacles( 1,  0),
      [5] = enemy:test_obstacles( 1, -1),
      [6] = enemy:test_obstacles( 0, -1),
      [7] = enemy:test_obstacles(-1, -1)
    }

    -- Return the normal angle for this direction if collision on the direction or the two surrounding ones, and no obstacle in the two next or obstacle in both.
    local function check_normal_angle(direction8)
      return ((collisions[direction8] or collisions[(direction8 - 1) % 8] and collisions[(direction8 + 1) % 8]) 
          and not xor(collisions[(direction8 - 2) % 8], collisions[(direction8 + 2) % 8])
          and direction8 * eighth)
    end

    -- Check for obstacles on each direction8 and return the normal angle if it is the correct one.
    local normal_angle
    for direction8 = 0, 7 do
      normal_angle = normal_angle or check_normal_angle(direction8)
    end

    return normal_angle
  end

  -- Return the angle after bouncing against close obstacles towards the given angle, or nil if no obstacles.
  function enemy:get_obstacles_bounce_angle(angle)

    local normal_angle = enemy:get_obstacles_normal_angle()
    if not normal_angle then
      return
    end
    angle = angle or enemy:get_movement():get_angle()

    return (2.0 * normal_angle - angle + math.pi) % circle
  end

  -- Make the enemy straight move.
  function enemy:start_straight_walking(angle, speed, distance, on_stopped_callback)

    local movement = sol.movement.create("straight")
    movement:set_speed(speed)
    movement:set_max_distance(distance or 0)
    movement:set_angle(angle)
    movement:set_smooth(true)
    movement:start(enemy)

    -- Consider the current move as stopped if finished or stuck.
    function movement:on_finished()
      if on_stopped_callback then
        on_stopped_callback()
      end
    end
    function movement:on_obstacle_reached()
      movement:stop()
      if on_stopped_callback then
        on_stopped_callback()
      end
    end

    -- Update the enemy sprites.
    for _, sprite in enemy:get_sprites() do
      if sprite:has_animation("walking") and sprite:get_animation() ~= "walking" then
        sprite:set_animation("walking")
      end
      sprite:set_direction(movement:get_direction4())
    end

    return movement
  end

  -- Make the enemy move to the entity.
  function enemy:start_target_walking(entity, speed)

    local movement = sol.movement.create("target")
    movement:set_speed(speed)
    movement:set_target(entity)
    movement:start(enemy)

    -- Update enemy sprites.
    local direction = movement:get_direction4()
    for _, sprite in enemy:get_sprites() do
      if sprite:has_animation("walking") and sprite:get_animation() ~= "walking" then
        sprite:set_animation("walking")
      end
      sprite:set_direction(direction)
    end
    function movement:on_position_changed()
      if movement:get_direction4() ~= direction then
        direction = movement:get_direction4()
        for _, sprite in enemy:get_sprites() do
          sprite:set_direction(direction)
        end
      end
    end

    return movement
  end

  -- Make the enemy start jumping.
  function enemy:start_jumping(duration, height, angle, speed, on_finished_callback)

    local movement

    -- Schedule an update of the sprite vertical offset by frame.
    local elapsed_time = 0
    sol.timer.start(enemy, 10, function()

      elapsed_time = elapsed_time + 10
      if elapsed_time < duration then
        for _, sprite in enemy:get_sprites() do
          sprite:set_xy(0, -math.sqrt(math.sin(elapsed_time / duration * math.pi)) * height)
        end
        return true
      else
        for _, sprite in enemy:get_sprites() do
          sprite:set_xy(0, 0)
        end
        if movement and enemy:get_movement() == movement then
          movement:stop()
        end

        -- Call events once jump finished.
        if on_finished_callback then
          on_finished_callback()
        end
      end
    end)
    enemy:set_obstacle_behavior("flying")

    -- Move the enemy on-floor if requested.
    if angle then
      movement = sol.movement.create("straight")
      movement:set_speed(speed)
      movement:set_angle(angle)
      movement:set_smooth(false)
      movement:start(enemy)
    
      return movement
    end
  end

  -- Make the enemy start flying.
  function enemy:start_flying(take_off_duration, height, on_finished_callback)

    -- Make enemy sprites start elevating.
    local event_called = false
    for _, sprite in enemy:get_sprites() do
      local movement = sol.movement.create("straight")
      movement:set_speed(height * 1000 / take_off_duration)
      movement:set_max_distance(height)
      movement:set_angle(math.pi * 0.5)
      movement:set_ignore_obstacles(true)
      movement:start(sprite)

      -- Call on_finished_callback() at the first movement finished.
      if not event_called then
        event_called = true
        function movement:on_finished()
          if on_finished_callback then
            on_finished_callback()
          end
        end
      end
    end
    enemy:set_obstacle_behavior("flying")
  end

  -- Make the enemy stop flying.
  function enemy:stop_flying(landing_duration, on_finished_callback)

    -- Make the enemy sprites start landing.
    local event_called = false
    for _, sprite in enemy:get_sprites() do
      local _, height = sprite:get_xy()
      height = math.abs(height)

      local movement = sol.movement.create("straight")
      movement:set_speed(height * 1000 / landing_duration)
      movement:set_max_distance(height)
      movement:set_angle(-math.pi * 0.5)
      movement:set_ignore_obstacles(true)
      movement:start(sprite)

      -- Call on_finished_callback() at the first movement finished.
      if not event_called then
        event_called = true
        function movement:on_finished()
          if on_finished_callback then
            on_finished_callback()
          end
        end
      end
    end
  end

  -- Start attracting the given entity, negative speed possible.
  function enemy:start_attracting(entity, speed, moving_condition_callback)

    -- Workaround : Don't use solarus movements to be able to start several movements at the same time.
    local move_ratio = speed > 0 and 1 or -1
    enemy:stop_attracting(entity)
    attracting_timers[entity] = {}

    local function attract_on_axis(axis)

      -- Clean the enemy if the entity was removed from outside.
      if not entity:exists() then
        enemy:stop_attracting(entity)
        return
      end

      local entity_position = {entity:get_position()}
      local enemy_position = {enemy:get_position()}
      local angle = math.atan2(entity_position[2] - enemy_position[2], enemy_position[1] - entity_position[1])
      
      local axis_move = {0, 0}
      local axis_move_delay = 10 -- Default timer delay if no move

      if not moving_condition_callback or moving_condition_callback() then

        -- Always move pixel by pixel.
        axis_move[axis] = math.max(-1, math.min(1, enemy_position[axis] - entity_position[axis])) * move_ratio
        if axis_move[axis] ~= 0 then

          -- Schedule the next move on this axis depending on the remaining distance and the speed value, avoiding too high and low timers.
          axis_move_delay = 1000.0 / math.max(1, math.min(1000, math.abs(speed * trigonometric_functions[axis](angle))))

          -- Move the entity.
          if not entity:test_obstacles(axis_move[1], axis_move[2]) then
            entity:set_position(entity_position[1] + axis_move[1], entity_position[2] + axis_move[2], entity_position[3])
          end
        end
      end

      return axis_move_delay
    end

    -- Start the pixel move schedule.
    for i = 1, 2 do
      local initial_delay = attract_on_axis(i)
      if initial_delay then
        attracting_timers[entity][i] = sol.timer.start(enemy, initial_delay, function()
          return attract_on_axis(i)
        end)
      end
    end
  end

  -- Stop looped timers related to the attractions.
  function enemy:stop_attracting(entity)

    for attracted_entity, timers in pairs(attracting_timers) do
      if timers and (not entity or entity == attracted_entity) then
        for i = 1, 2 do
          if timers[i] then
            timers[i]:stop()
          end
        end
      end
    end
  end

  -- Start a straight move to the given target and apply a constant acceleration and deceleration (px/s²).
  function enemy:start_impulsion(x, y, speed, acceleration, deceleration)

    -- Workaround : Don't use solarus movements to be able to start several movements at the same time.
    local movement = {}
    local timers = {}
    local angle = enemy:get_angle(x, y)
    local start = {enemy:get_position()}
    local target = {x, y}
    local accelerations = {acceleration, acceleration}
    local ignore_obstacles = false

    -- Call given event on the movement table.
    local function call_event(event)
      if event then
        event(movement)
      end
    end

    -- Schedule 1 pixel moves on each axis depending on the given acceleration.
    local function move_on_axis(axis)

      local axis_current_speed = math.abs(trigonometric_functions[axis](angle) * 2.0 * acceleration)
      local axis_maximum_speed = math.abs(trigonometric_functions[axis](angle) * speed)
      local axis_move = {[axis % 2 + 1] = 0, [axis] = math.max(-1, math.min(1, target[axis] - start[axis]))}

      -- Avoid too low speed (less than 1px/s).
      if axis_current_speed < 1 then
        accelerations[axis] = 0
        return
      end

      return sol.timer.start(enemy, 1000.0 / axis_current_speed, function()

        -- Move enemy if it wouldn't reach an obstacle.
        local position = {enemy:get_position()}
        if ignore_obstacles or not enemy:test_obstacles(axis_move[1], axis_move[2]) then
          enemy:set_position(position[1] + axis_move[1], position[2] + axis_move[2], position[3])
          call_event(movement.on_position_changed)
        else
          call_event(movement.on_obstacle_reached)
          timers[axis] = nil
          return false
        end

        -- Replace axis acceleration by negative deceleration if beyond axis target.
        local axis_position = position[axis] + axis_move[axis]
        if accelerations[axis] > 0 and math.min(start[axis], axis_position) <= target[axis] and target[axis] <= math.max(start[axis], axis_position) then
          accelerations[axis] = -deceleration
          call_event(movement.on_changed)

          -- Call decelerating callback if both axis timers are decelerating.
          if accelerations[axis % 2 + 1] <= 0 then
            call_event(movement.on_decelerating)
          end
        end

        -- Update speed between 0 and maximum speed (px/s) depending on acceleration.
        axis_current_speed = math.min(math.sqrt(math.max(0, math.pow(axis_current_speed, 2.0) + 2.0 * accelerations[axis])), axis_maximum_speed)     

        -- Schedule the next pixel move and avoid too low timers (less than 1px/s).
        if axis_current_speed >= 1 then
          return 1000.0 / axis_current_speed
        end

        -- Call on_finished() event when the last axis timers finished normally.
        timers[axis] = nil
        if not timers[axis % 2 + 1] then
          call_event(movement.on_finished)
        end
      end)
    end
    timers = {move_on_axis(1), move_on_axis(2)}

    -- TODO Reproduce generic build-in movement methods on the returned movement table.
    function movement:stop()
      for i = 1, 2 do
        if timers[i] then
          timers[i]:stop()
        end
      end
    end
    function movement:set_ignore_obstacles(ignore)
      ignore_obstacles = ignore or true
    end
    function movement:get_direction4()
      return math.floor((angle / circle * 8 + 1) % 8 / 2)
    end

    return movement
  end

  -- Throw the given entity.
  function enemy:start_throwing(entity, duration, start_height, maximum_height, angle, speed, on_finished_callback)

    local movement
    maximum_height = maximum_height or start_height

    -- Consider the throw as an already-started sinus function, depending on start_height.
    local elapsed_time = duration / (1 - math.asin(math.pow(start_height / maximum_height, 2)) / math.pi) - duration
    duration = duration + elapsed_time

    -- Schedule an update of the sprite vertical offset by frame.
    sol.timer.start(entity, 10, function()

      elapsed_time = elapsed_time + 10
      if elapsed_time < duration then
        for sprite_name, sprite in entity:get_sprites() do
          if sprite_name ~= "shadow" and sprite_name ~= "shadow_override" then -- Workaround : Don't change shadow height when the sprite is part of the entity.
            sprite:set_xy(0, -math.sqrt(math.sin(elapsed_time / duration * math.pi)) * maximum_height)
          end
        end
        return true
      else
        for _, sprite in entity:get_sprites() do
          sprite:set_xy(0, 0)
        end
        if movement and entity:get_movement() == movement then
          movement:stop()
        end

        -- Call events once jump finished.
        if on_finished_callback then
          on_finished_callback()
        end
      end
    end)

    -- Move the entity on-floor if requested.
    if angle then
      movement = sol.movement.create("straight")
      movement:set_speed(speed)
      movement:set_angle(angle)
      movement:set_smooth(false)
      movement:start(entity)
    
      return movement
    end
  end

  -- Make the entity welded to the enemy at the given offset position, and propagate main events and methods.
  function enemy:start_welding(entity, x, y)

    x = x or 0
    y = y or 0
    enemy:register_event("on_update", function(enemy) -- Workaround : Replace the entity in on_update() instead of on_position_changed() to take care of hurt movements.
      local enemy_x, enemy_y, enemy_layer = enemy:get_position()
      entity:set_position(enemy_x + x, enemy_y + y, enemy_layer)
    end)
    enemy:register_event("on_removed", function(enemy)
      if entity:exists() then
        entity:remove()
      end
    end)
    enemy:register_event("on_enabled", function(enemy)
      entity:set_enabled()
    end)
    enemy:register_event("on_disabled", function(enemy)
      entity:set_enabled(false)
    end)
    enemy:register_event("on_dead", function(enemy)
      if entity:exists() then
        entity:remove()
      end
    end)
    enemy:register_event("set_visible", function(enemy, visible)
      entity:set_visible(visible)
    end)
  end

  -- Set a maximum distance between the enemy and an entity, else replace the enemy near it.
  function enemy:start_leashed_by(entity, maximum_distance)

    leashing_timers[entity] = sol.timer.start(enemy, 10, function()
      
      if enemy:get_distance(entity) > maximum_distance then
        local enemy_x, enemy_y, layer = enemy:get_position()
        local hero_x, hero_y, _ = hero:get_position()
        local vX = enemy_x - hero_x;
        local vY = enemy_y - hero_y;
        local magV = math.sqrt(vX * vX + vY * vY);
        local x = hero_x + vX / magV * maximum_distance;
        local y = hero_y + vY / magV * maximum_distance;

        -- Move the entity.
        if not enemy:test_obstacles(x - enemy_x, y - enemy_y) then
          enemy:set_position(x, y, layer)
        end
      end

      return true
    end)
  end

  -- Stop the leashing attraction on the given entity
  function enemy:stop_leashed_by(entity)
    if leashing_timers[entity] then
      leashing_timers[entity]:stop()
      leashing_timers[entity] = nil
    end
  end

  -- Start pushing back the enemy.
  function enemy:start_pushed_back(entity, speed, duration, on_finished_callback)

    local movement = sol.movement.create("straight")
    movement:set_speed(speed or 100)
    movement:set_angle(entity:get_angle(enemy))
    movement:set_smooth(false)
    movement:start(enemy)

    sol.timer.start(enemy, duration or 150, function()
      movement:stop()
      if on_finished_callback then
        on_finished_callback()
      end
    end)
  end

  -- Start pushing the entity back.
  function enemy:start_pushing_back(entity, speed, duration, on_finished_callback)
    
    -- Workaround: Movement crashes sometimes when used at the wrong time on the hero, use a negative attraction instead.
    enemy:start_attracting(entity, -speed or 100)

    sol.timer.start(enemy, duration or 150, function()
      enemy:stop_attracting()
      if on_finished_callback then
        on_finished_callback()
      end
    end)
  end

  -- Start pushing both enemy and entity back with an impact effect.
  function enemy:start_shock(entity, speed, duration, on_finished_callback)

    local x, y, _ = enemy:get_position()
    local hero_x, hero_y, _ = hero:get_position()
    enemy:start_pushing_back(hero, speed or 100, duration or 150)
    enemy:start_pushed_back(hero, speed or 100, duration or 150, function()
      if on_finished_callback then
        on_finished_callback()
      end
    end)
    enemy:start_brief_effect("entities/effects/impact_projectile", "default", (hero_x - x) / 2, (hero_y - y) / 2)
  end

  -- Make the enemy die as described in the given dying_callback, or silently and without animation if nil.
  -- Stop all actions and prevent interactions when the function starts, then run the dying_callback which will finish_death() manually when needed.
  -- Additionnal helper functions are accessible from the callback to describe the death :
  --   set_treasure_falling_height(height) -> Set the treasure falling height in pixel, which is 8 by default.
  --   finish_death() -> Start all behaviors related to the enemy actual death, basically treasure drop, savegame and removal.
  function enemy:start_death(dying_callback)

    local dying_helpers = {}
    local treasure_falling_height = 8
    enemy.is_hurt_silently = true -- Workaround : Don't play generic sounds added by enemy meta script.

    -- Stop all running actions and call on_dying() event.
    enemy:stop_all()
    if enemy.on_dying then
      enemy:on_dying()
    end

    -- Helper function to set the treasure falling height in pixel.
    function dying_helpers.set_treasure_falling_height(height)
      treasure_falling_height = height
    end

    -- Helper function to start all behaviors related to the enemy actual death, basically treasure drop, savegame and removal.
    function dying_helpers.finish_death()

      -- Make a possible treasure appear.
      local treasure_name, treasure_variant, treasure_savegame = enemy:get_treasure()
      if treasure_name then
        local x, y, layer = enemy:get_position()
        local pickable = map:create_pickable({
          x = x,
          y = y,
          layer = layer,
          treasure_name = treasure_name,
          treasure_variant = treasure_variant,
          treasure_savegame_variable = treasure_savegame
        })

        -- Replace the built-in falling by a throw from the given height.
        if pickable and pickable:exists() then -- If the pickable was not immediately removed from the on_created() event.
          if pickable:get_treasure():get_name() ~= "fairy" then -- Workaround: No way to set no built-in falling movement nor detect it from a movement initiated in on_created. Don't stop the movement for some items.
            pickable:stop_movement()
            enemy:start_throwing(pickable, 450 + treasure_falling_height * 6, treasure_falling_height, treasure_falling_height + 16) -- TODO Find a better way to set a duration.
          end
        end
      end

      -- TODO Handle savegame if any.

      -- Actual removal and on_dead() event call.
      enemy:remove()
      if enemy.on_dead then
        enemy:on_dead()
      end
    end

    -- Die as described in the dying_callback if given, else kill the enemy without any animation. 
    if dying_callback then
      setmetatable(dying_helpers, {__index=getfenv(2)})
      setfenv(dying_callback, dying_helpers)
      dying_callback()
    else
      dying_helpers.finish_death()
    end
  end

  -- Add a shadow below the enemy.
  function enemy:start_shadow(sprite_name, animation_name, x, y)

    if not shadow then
      local enemy_x, enemy_y, enemy_layer = enemy:get_position()
      shadow = map:create_custom_entity({
        direction = 0,
        x = enemy_x + (x or 0),
        y = enemy_y + (y or 0),
        layer = enemy_layer,
        width = 16,
        height = 16,
        sprite = sprite_name or "entities/shadows/shadow"
      })
      enemy:start_welding(shadow, x, y)

      if animation_name then
        shadow:get_sprite():set_animation(animation_name)
      end
      shadow:set_traversable_by(true)
      shadow:set_drawn_in_y_order(false) -- Display the shadow as a flat entity.
      shadow:bring_to_back()
      
      -- Always display the shadow on the lowest possible layer.
      function shadow:on_position_changed(x, y, layer)
        for ground_layer = enemy:get_layer(), map:get_min_layer(), -1 do
          if map:get_ground(x, y, ground_layer) ~= "empty" then
            if shadow:get_layer() ~= ground_layer then
              shadow:set_layer(ground_layer)
            end
            break
          end
        end
      end
    end

    -- Make the shadow disappear when the enemy became invisible on dying.
    enemy:register_event("on_dying", function(enemy)
      sol.timer.start(shadow, 300, function() -- No event when the enemy became invisible, hardcode a timer.
        shadow:remove()
      end)
    end)

    return shadow
  end

  -- Start a standalone sprite animation on the enemy position, that will be removed once finished or maximum_duration reached if given.
  function enemy:start_brief_effect(sprite_name, animation_name, x, y, maximum_duration, on_finished_callback)

    local enemy_x, enemy_y, enemy_layer = enemy:get_position()
    local entity = map:create_custom_entity({
        sprite = sprite_name,
        x = enemy_x + (x or 0),
        y = enemy_y + (y or 0),
        layer = enemy_layer,
        width = 80,
        height = 32,
        direction = 0
    })
    entity:set_drawn_in_y_order()

    -- Remove the entity once animation finished or max_duration reached.
    local function on_finished()
      if on_finished_callback then
        on_finished_callback()
      end
      if entity:exists() then
        entity:remove()
      end
    end
    local sprite = entity:get_sprite()
    sprite:set_animation(animation_name or sprite:get_animation(), function()
      on_finished()
    end)
    if maximum_duration then
      sol.timer.start(entity, maximum_duration, function()
        on_finished()
      end)
    end

    return entity
  end

  -- Start a new explosion placed randomly around the entity coordinates each time the previous one finished, until duration reached.
  function enemy:start_close_explosions(maximum_distance, duration, explosion_sprite_name, x, y, on_finished_callback)

    explosion_sprite_name = explosion_sprite_name or "entities/explosion_boss"
    x = x or 0
    y = y or 0

    local elapsed_time = 0
    local function start_close_explosion()
      local random_distance = math.random() * maximum_distance
      local random_angle = math.random(circle)
      local random_x = math.cos(random_angle) * random_distance
      local random_y = math.sin(random_angle) * random_distance
      
      local explosion = enemy:start_brief_effect(explosion_sprite_name, nil, random_x + x, random_y + y, nil, function()
        if elapsed_time < duration then
          start_close_explosion()
        else
          if on_finished_callback then
            on_finished_callback()
          end
        end
      end)
      explosion:set_layer(enemy:get_layer() + 1)
      local sprite = explosion:get_sprite()
      elapsed_time = elapsed_time + sprite:get_frame_delay() * sprite:get_num_frames()
    end
    start_close_explosion()
  end

  -- Make the given enemy sprites explode one after the other in the given order, and remove exploded sprite.
  function enemy:start_sprite_explosions(sprites, explosion_sprite_name, x, y, on_finished_callback)

    sprites = sprites or enemy:get_sprites()
    explosion_sprite_name = explosion_sprite_name or "entities/explosion_boss"
    x = x or 0
    y = y or 0

    local function start_sprite_explosion(index)
      local sprite = sprites[index]
      local sprite_x, sprite_y = sprite:get_xy()
      local explosion = enemy:start_brief_effect(explosion_sprite_name, nil, sprite_x + x, sprite_y + y, nil, function()
        if index < #sprites then
          start_sprite_explosion(index + 1)
        else
          if on_finished_callback then
            on_finished_callback()
          end
        end
      end)
      explosion:set_layer(enemy:get_layer() + 1)
      enemy:remove_sprite(sprite)
    end
    start_sprite_explosion(1)
  end

  -- Stop all running actions and prevent interactions with other entities.
  function enemy:stop_all()

    sol.timer.stop_all(enemy)
    enemy:stop_movement()
    enemy:set_can_attack(false)
    enemy:set_invincible()
  end
end

return common_actions