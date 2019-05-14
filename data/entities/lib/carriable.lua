----------------------------------
--
-- Undestructible destructible map entity, behaving the same way than build-in destructible except it bounces instead of breaking.
-- A hit happen when the entity reaches an obstacle or when the carriable sprite overlaps another entity sprite while the throw is still running.
-- 
-- Methods : carriable:throw(direction)
-- Events :  carriable:on_thrown(direction)
--           carriable:on_bounce(num_bounce)
--           carriable:on_finish_throw()
--           carriable:on_hit(entity)
--           entity:on_hit_by_carriable(carriable)
--
-- Usage : 
-- local my_entity = ...
-- local carriable_behavior = require("entities/lib/carriable")
-- carriable_behavior.apply(my_entity, { --[[ Custom properties --]] } )
--
----------------------------------

local carriable_behavior = {}

local default_properties = {

  bounce_distances = {80, 16, 4}, -- Distances for each bounce.
  bounce_durations = {400, 160, 70}, -- Duration for each bounce.
  bounce_heights = {nil, 4, 2}, -- Heights for each bounce. Nil means sprite position.
  bounce_sound = nil, -- Default id of the bouncing sound. Nil means no sound.
  hurt_strength = 2, -- Default life points subtracted on an enemy hit.
  respawn_delay = nil, -- Time before respawn when removed by bad grounds. Nil means no respawn.
  shadow_sprite = nil, -- Sprite of the shadow. A default one is used if nil.
  slowdown_ratio = 0.5, -- Speed and distance decrease ratio at each obstacle hit.
}

function carriable_behavior.apply(carriable, properties)

  local game = carriable:get_game()
  local map = carriable:get_map()
  local hero = map:get_hero()
  local sprite = carriable:get_sprite()

  -- Function to set the main sprite animation if it exists.
  local function set_animation_if_exists(animation)
    if sprite:has_animation(animation) and sprite:get_animation(animation) ~= animation then
      sprite:set_animation(animation)
    end
  end

  -- Function to call hit events, the entity parameter may be nil.
  local function call_hit_events(entity)
    if entity and entity.on_hit_by_carriable then
      entity:on_hit_by_carriable(carriable)
    end
    if carriable.on_hit then
      carriable:on_hit(entity)
    end
  end

  -- Function to make the carriable not traversable by the hero and vice versa. 
  -- Delay this moment if the hero would get stuck.
  local function set_hero_not_traversable_safely(entity)
    if not entity:overlaps(map:get_hero()) then
      entity:set_traversable_by("hero", false)
      entity:set_can_traverse("hero", false)
      return
    end
    sol.timer.start(10, function() -- Retry later.
      set_hero_not_traversable_safely(entity)
    end)
  end

  -- Return true if the parameter is an obstacle entity.
  -- TODO Check for something like entity1:is_traversable_by(entity2) and remove this temp function
  local function is_obstacle(entity)
    local obstacle_entities = {"crystal", "custom_entity", "enemy"}
    for _, entity_type in pairs(obstacle_entities) do
      if entity:get_type() == entity_type then
        return true
      end
    end
    return false
  end

  -- Simulate the movement that hasn't been commited and return a table with overlapping entities.
  -- TODO Check for something like movement:on_obstacle_reached(entities) and remove this temp function
  local function get_overlapping_entities_on_obstacle_reached(movement)
    local overlapping_entities = {}
    local speed = movement:get_speed()
    local angle = movement:get_angle()
    local movement_x = speed / 100 * math.cos(angle)
    local movement_y = speed / 100 * math.sin(angle)
    local x, y, width, height = carriable:get_max_bounding_box()
    local entities = map:get_entities_in_rectangle(x + movement_x, y + movement_y, width, height)  
    for entity in entities do
      if entity ~= carriable then
        table.insert(overlapping_entities, entity)
      end
    end
    return overlapping_entities
  end

  -- Throwing method, define behavior for the thrown carriable.
  carriable:register_event("throw", function(carriable, direction)

    -- Properties.
    local bounce_distances = properties.bounce_distances or default_properties.bounce_distances
    local bounce_durations = properties.bounce_durations or default_properties.bounce_durations
    local bounce_heights = properties.bounce_heights or default_properties.bounce_heights
    local bounce_sound = properties.bounce_sound or default_properties.bounce_sound
    local hurt_strength = properties.hurt_strength or default_properties.hurt_strength
    local respawn_delay = properties.respawn_delay or default_properties.respawn_delay
    local shadow_sprite = properties.shadow_sprite or default_properties.shadow_sprite
    local slowdown_ratio = properties.slowdown_ratio or default_properties.slowdown_ratio

    -- Initialize throwing state.
    local num_bounces = #bounce_distances
    local current_bounce = 1
    local current_instant = 0
    local is_bounce_movement_starting = true -- True when the carriable is not moving, but about to.
    local dx, dy = math.cos(direction * math.pi / 2), -math.sin(direction * math.pi / 2)
    local _, hero_height = map:get_entity("hero"):get_size()

    carriable:set_direction(direction)
    set_hero_not_traversable_safely(carriable)
    sprite:set_xy(0, -hero_height - 6)
    set_animation_if_exists("thrown")

    -- Function to hurt an enemy vulnerable to thrown items.
    local function hurt_if_vulnerable(entity)
      if entity and entity:get_type() == "enemy" and entity:get_attack_consequence("thrown_item") ~= "ignored" then
        entity:hurt(hurt_strength)
      end
    end

    -- Callback function for bad ground bounce.
    -- Remove the carriable and respawn it after a delay if the property is set.
    local function on_bad_ground_bounce()
      local initial_properties = {
          name = carriable:get_name(), model = carriable:get_model(), properties = carriable:get_properties(),
          x = carriable.respawn_position.x, y = carriable.respawn_position.y, layer = carriable.respawn_position.layer, 
          direction = carriable:get_direction(), sprite = sprite:get_animation_set(),
          width = 16, height = 16}
      carriable:remove()
      if respawn_delay then
        sol.timer.start(respawn_delay, function()
          map:create_custom_entity(initial_properties)
        end)
      end
    end

    -- Reverse throwing direction and slow down all bounces including the current movement.
    local function reverse_direction(slowdown_ratio)
      local movement = carriable:get_movement()
      direction = (direction + 2) % 4
      if movement then 
        local slowed_distances = {} -- New table to not override default properties.
        movement:set_angle(movement:get_angle() + math.pi)
        movement:set_max_distance(movement:get_max_distance() * slowdown_ratio)
        movement:set_speed(movement:get_speed() * slowdown_ratio)
        for _, distance in ipairs(bounce_distances) do
          table.insert(slowed_distances, math.floor(distance * slowdown_ratio))
        end
        bounce_distances = slowed_distances
      end
    end

    -- Callback function for collision test.
    -- Call hit events and reverse the movement if needed.
    local function carriable_on_collision(carriable, entity)
      if entity and entity:is_enabled() then
        hurt_if_vulnerable(entity)
        call_hit_events(entity)
        if is_obstacle(entity) then
          reverse_direction(slowdown_ratio)
        end
      end
    end

    -- A hit may happen on sprite collision without reaching an obstacle when entities are not on the same row nor column.
    carriable:add_collision_test("sprite", carriable_on_collision) -- TODO Seems buggy between custom entities

    -- Create a sprite for the shadow.
    if not shadow_sprite then
      shadow_sprite = carriable:create_sprite("entities/shadows/shadow", "shadow")
      carriable:bring_sprite_to_back(shadow_sprite) -- TODO handle lifting when shadow still exists
    end

    -- Function called when the carriable has fallen.
    local function finish_bounce()
      carriable:clear_collision_tests()
      carriable:stop_movement()
      carriable:remove_sprite(shadow_sprite)
      set_animation_if_exists("stopped")
      if carriable.on_finish_throw then
        carriable:on_finish_throw() -- Call event
      end
    end
      
    -- Function to bounce when carriable is thrown.
    local function bounce()

      -- Finish bouncing if we have already done them all.
      if current_bounce > num_bounces then 
        finish_bounce()    
        return
      end  

      -- Initialize parameters for the bounce.
      local _, sy = sprite:get_xy()
      local t = current_instant
      local dist = bounce_distances[current_bounce]
      local dur = bounce_durations[current_bounce] 
      local h = bounce_heights[current_bounce] or -sy
      local speed = 1000 * dist / dur
      
      -- Function to compute height for each fall (bounce).
      local function current_height()
        if current_bounce == 1 then
          return h * ((t / dur) ^ 2 - 1)
        end
        return 4 * h * ((t / dur) ^ 2 - t / dur)
      end

      -- Start this bounce movement if the previous one ended normally or if the carriable is still moving.
      if is_bounce_movement_starting or carriable:get_movement() then
        local movement = sol.movement.create("straight")
        movement:set_angle(direction * math.pi / 2)
        movement:set_speed(speed)
        movement:set_max_distance(dist)
        movement:set_smooth(false)
        function movement:on_finished()
          is_bounce_movement_starting = true -- The movement ended without being stopped by an obstacle or from another script.
        end
        -- Call events and reverse direction on obstacle reached.
        function movement:on_obstacle_reached()
          local entities = get_overlapping_entities_on_obstacle_reached(movement)
          for _, entity in pairs(entities) do
            if entity and entity:is_enabled() then
              hurt_if_vulnerable(entity)
              call_hit_events(entity)
            end
          end
          if #entities == 0 then -- Call hit events even if the obstacle is not an entity.
            call_hit_events(nil)
          end
          reverse_direction(slowdown_ratio)
        end
        is_bounce_movement_starting = false
        movement:start(carriable)
      end
      
      -- Start shifting height of the carriable at each instant for current bounce.
      local refreshing_time = 5 -- Time between computations of each position.
      sol.timer.start(carriable, refreshing_time, function()
        t = t + refreshing_time
        current_instant = t
        -- Update shift of sprite.
        if t <= dur then 
          sprite:set_xy(0, current_height())
        -- Stop the timer. Start next bounce or finish bounces. 
        else -- The carriable hits the ground.
          map:ground_collision(carriable, bounce_sound, on_bad_ground_bounce)
          -- Check if the carriable still exists (it can be removed on holes, water and lava).
          if carriable:exists() then
            if carriable.on_bounce then
              carriable:on_bounce(current_bounce) -- Call event
            end
            current_bounce = current_bounce + 1
            current_instant = 0
            bounce() -- Start next bounce.
          end
          return false
        end
        return true
      end)
    end

    if carriable.on_thrown then
      carriable:on_thrown() -- Call event
    end

    -- Start the first bounce.
    bounce()
  end)

  carriable:register_event("on_created", function(carriable)

    -- General properties.
    local x, y, layer = carriable:get_position()
    carriable.respawn_position = {x = x, y = y, layer = layer}
    carriable:set_follow_streams(true)
    carriable:set_traversable_by(false)
    carriable:set_drawn_in_y_order(true)
    carriable:set_weight(0)
    carriable:bring_to_front()
    set_animation_if_exists("stopped")

    -- Traversable rules.
    carriable:set_can_traverse_ground("deep_water", true)
    carriable:set_can_traverse_ground("grass", true)
    carriable:set_can_traverse_ground("hole", true)
    carriable:set_can_traverse_ground("lava", true)
    carriable:set_can_traverse_ground("low_wall", true)
    carriable:set_can_traverse_ground("prickles", true)
    carriable:set_can_traverse_ground("shallow_water", true)
    carriable:set_can_traverse("crystal_block", true)
    carriable:set_can_traverse("stream", true)
    carriable:set_can_traverse("switch", true)
    carriable:set_can_traverse("teletransporter", true)
    carriable:set_can_traverse(false)

    -- Set the hero not traversable as soon as possible, to avoid being stuck if the carriable is (re)created on the hero.
    carriable:set_traversable_by("hero", true)
    carriable:set_can_traverse("hero", true)
    set_hero_not_traversable_safely(carriable)

    -- Custom lifting and carrying steps.
    carriable:register_event("on_interaction", function(carriable)

      -- Start a custom lifting to not destroy the carriable and keep events registered outside the entity script alive.
      local x, y, layer = hero:get_position()
      adjust_direction = {
        [0] = function () x = x + 16 end,
        function () y = y - 16 end,
        function () x = x - 16 end,
        function () y = y + 16 end,
      }
      adjust_direction[hero:get_direction()]()
      carriable:set_position(x, y, layer)
      hero:freeze()

      -- Lifting movement.
      local lifting_trajectories = {
        [0] = {{0, 0}, {0, 0}, {-3, -6}, {-5, -6},  {-5, -4}},
        {{0, 0}, {0, 0}, {0, -1}, {0, -1}, {0, 0}},
        {{0, 0}, {0, 0}, {3, -6},  {5, -6}, {5, -4}},
        {{0, 0}, {0, 0}, {0, -10}, {0, -12}, {0, 0}}}
      local movement = sol.movement.create("pixel")
      movement:set_trajectory(lifting_trajectories[hero:get_direction()])
      movement:set_ignore_obstacles(true)
      movement:set_delay(100)
      movement:start(sprite)

      -- Start a custom carrying state when the lifting animation finished.
      hero:set_animation("lifting", function()

        local carrying_state = sol.state.create()
        carrying_state:set_can_interact(false)
        carrying_state:set_can_grab(false)
        carrying_state:set_can_push(false)

        function carrying_state:on_started()
          set_animation_if_exists("walking")
          if game:is_command_pressed("right") or game:is_command_pressed("left") or game:is_command_pressed("up") or game:is_command_pressed("down") then
            hero:set_animation("carrying_walking")
          else
            hero:set_animation("carrying_stopped")
            sprite:set_paused(true)
          end
          carriable:set_traversable_by("hero", true)
          carriable:set_can_traverse("hero", true)
          sprite:set_xy(0, -18)
        end

        -- Throw the carriable when the state finished, whatever the reason is.
        function carrying_state:on_finished()
          sprite:set_paused(false)
          carriable:throw(hero:get_direction())
        end

        -- Make carriable follow hero moves.
        function carrying_state:on_update()
          local x, y, layer = hero:get_position()
          carriable:set_position(x, y, layer)
        end
        
        function carrying_state:on_command_pressed(command)
          -- Throw the carriable on action command pressed.
          if command == "action"  then
            hero:unfreeze() -- Stop the carrying state.
          end
          -- Start walking animation on direction command pressed.
          if command == "right" or command == "left" or command == "up" or command == "down" then
            hero:set_animation("carrying_walking")
            sprite:set_paused(false)
          end
        end

        -- Start stopped animation if no direction command is pressed.
        function carrying_state:on_command_released(command)
          if not game:is_command_pressed("right") and not game:is_command_pressed("left") and not game:is_command_pressed("up") and not game:is_command_pressed("down") then
            hero:set_animation("carrying_stopped")
            sprite:set_paused(true)
          end
          -- Workaround : Resynchronize carriable and hero sprites on direction command released.
          if command == "right" or command == "left" or command == "up" or command == "down" then
            sprite:set_frame(0)
            hero:get_sprite():set_frame(0)
          end
        end
        hero:start_state(carrying_state)
      end)
    end)
  end)
end

return carriable_behavior