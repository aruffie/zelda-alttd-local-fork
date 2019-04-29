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

  num_bounces = 3, -- Number of bounces when falling (it can be 0).
  bounce_distances = {80, 16, 4}, -- Distances for each bounce.
  bounce_durations = {400, 160, 70}, -- Duration for each bounce.
  bounce_heights = {"same", 4, 2}, -- Heights for each bounce.
  bounce_sound = nil, -- Default id of the bouncing sound. Nil means no sound.
  hurt_strength = 2, -- Default life points subtracted on an enemy hit.
  respawn_delay = nil, -- Time before respawn when removed by bad grounds. Nil means no respawn.
  shadow_type = "normal", -- Type of shadow for the falling trajectory.
  slowdown_ratio = 0.5, -- Speed and distance decrease ratio at each obstacle hit.
  vshift = 0 -- Vertical shift to draw the sprite while lifting/carrying.
}

function carriable_behavior.apply(carriable, properties)

  local map = carriable:get_map()

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
    local obstacle_entities = {"crystal", "enemy"}
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
    local num_bounces = properties.num_bounces or default_properties.num_bounces
    local bounce_distances = properties.bounce_distances or default_properties.bounce_distances
    local bounce_durations = properties.bounce_durations or default_properties.bounce_durations
    local bounce_heights = properties.bounce_heights or default_properties.bounce_heights
    local bounce_sound = properties.bounce_sound or default_properties.bounce_sound
    local hurt_strength = properties.hurt_strength or default_properties.hurt_strength
    local respawn_delay = properties.respawn_delay or default_properties.respawn_delay
    local shadow_type = properties.shadow_type or default_properties.shadow_type
    local slowdown_ratio = properties.slowdown_ratio or default_properties.slowdown_ratio
    local vshift = properties.vshift or default_properties.vshift

    -- Initialize throwing state.
    local sprite = carriable:get_sprite()
    local current_bounce = 1
    local current_instant = 0
    local is_bounce_movement_starting = true -- True when the carriable is not moving, but about to.
    local dx, dy = math.cos(direction * math.pi / 2), -math.sin(direction * math.pi / 2)

    carriable:set_traversable_by("hero", true)
    carriable:set_can_traverse("hero", true)
    set_hero_not_traversable_safely(carriable) -- Set the hero not traversable as soon as possible.
    carriable:set_direction(direction)
    sprite:set_xy(0, -22 + vshift)

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
          direction = carriable:get_direction(), sprite = carriable:get_sprite():get_animation_set(),
          width = 16, height = 16}
      carriable:remove()
      if respawn_delay then
        sol.timer.start(respawn_delay, function()
          local respawned_carriable = map:create_custom_entity(initial_properties)
          respawned_carriable:set_traversable_by("hero", true)
          set_hero_not_traversable_safely(respawned_carriable) -- Set the hero not traversable as soon as possible.
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
      hurt_if_vulnerable(entity)
      call_hit_events(entity)
      if is_obstacle(entity) then
        reverse_direction(slowdown_ratio)
      end
    end

    -- A hit may happen on sprite collision without reaching an obstacle when entities are not on the same row nor column.
    carriable:add_collision_test("sprite", carriable_on_collision) -- TODO Seems buggy between custom entities

    -- Create a custom_entity for shadow (this one is drawn below).
    local px, py, pz = carriable:get_position()
    if shadow_type then
      local shadow_properties = {x = px, y = py, layer = pz, direction = 0, width = 16, height = 16}
      shadow = map:create_custom_entity(shadow_properties)
      if shadow_type == "normal" then
        shadow:create_sprite("entities/shadows/shadow")
        shadow:bring_to_back()
      end
      -- Remove shadow when the carriable is removed.
      function carriable:on_removed()
        shadow:remove()
      end
    end

    -- Function called when the carriable has fallen.
    local function finish_bounce()
      carriable:clear_collision_tests()
      carriable:stop_movement()
      if shadow then
        shadow:remove()
      end
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
      local h = bounce_heights[current_bounce]
      local speed = 1000 * dist / dur
      if h == "same" then
        h = -sy
      end
      
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
            hurt_if_vulnerable(entity)
            call_hit_events(entity)
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
        if shadow then
          shadow:set_position(carriable:get_position())
        end
        -- Update shift of sprite.
        if t <= dur then 
          sprite:set_xy(0, current_height() + vshift)
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

    -- Traversable rules.
    carriable:set_can_traverse_ground("deep_water", true)
    carriable:set_can_traverse_ground("shallow_water", true)
    carriable:set_can_traverse_ground("hole", true)
    carriable:set_can_traverse_ground("lava", true)
    carriable:set_can_traverse_ground("grass", true)
    carriable:set_can_traverse_ground("prickles", true)
    carriable:set_can_traverse_ground("low_wall", true)
    carriable:set_can_traverse("stream", true)
    carriable:set_can_traverse("switch", true)
    carriable:set_can_traverse("teletransporter", true)
    carriable:set_can_traverse(false)

    -- Behavior when carried.
    carriable:register_event("on_lifting", function(carriable, hero, carried_object)
      local carriable_name = carriable:get_name()
      local carriable_model = carriable:get_model()
      local carriable_properties = carriable:get_properties()
      -- TODO Find a proper way to keep events registered outside this script alive when the entity is replaced by the carried object
      local carriable_on_finish_throw = carriable.on_finish_throw
      
      -- Remove the build-in carried object when thrown and replace it by the initial custom entity with custom thrown trajectory.
      carried_object:register_event("on_thrown", function(carried_object)

        local hero = map:get_hero()
        local x, y, layer = hero:get_position()
        local direction = hero:get_direction()
        local animation_set = carried_object:get_sprite():get_animation_set()
        local initial_properties = {
            name = carriable_name, model = carriable_model, properties = carriable_properties,
            x = x, y = y, layer = layer, direction = direction, sprite = animation_set, width = 16, height = 16}

        carried_object:remove()
        local thrown_carriable = map:create_custom_entity(initial_properties)
        thrown_carriable.respawn_position = carriable.respawn_position -- Keep the initial respawn position.
        thrown_carriable.on_finish_throw = carriable_on_finish_throw -- TODO remove
        thrown_carriable:throw(direction)
      end)
    end)
  end)
end

return carriable_behavior