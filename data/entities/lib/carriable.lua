-- Lua script of carriable custom entity.
-- This script is executed every time a custom entity with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

----------------------------------
--
-- Behavior of an undestructible solarus destructible, 
-- behaving the same way than solarus destructible except it won't break.
-- 
-- Events : carriable:on_bounce(num_bounce), carriable:on_finish_throw(), entity:hit_by_carriable(carriable)
-- Methods : carriable:throw(direction)
--
----------------------------------

local carriable_behavior = {}

function carriable_behavior.apply(carriable, properties)

  local map = carriable:get_map()

  -- Function to fix bug: the hero may get stuck with the carriable if it falls over him.
  -- Modify ground of the carriable with a custom entity above, if necessary.
  local function avoid_overlap_with_hero(entity)

    -- Check if this destructible and hero overlap.
    local hero = entity:get_map():get_hero()
    if not hero:overlaps(entity) then
      return -- No overlapping. No need to move the destructible.
    end

    -- There is an overlap. Put the entity in front of hero.
    local x, y, layer = hero:get_position()
    local dir = hero:get_direction()
    local angle = dir * math.pi / 2
    x, y = x + 16 * math.cos(angle), y - 16 * math.sin(angle)
    entity:set_position(x, y, layer)
  end

  -- Define falling trajectory for the thrown carriable
  carriable:register_event("throw", function(carriable, direction)

    -- Initialize throwing state
    local sprite = carriable:get_sprite()
    local current_bounce = 1
    local current_instant = 0
    local dx, dy = math.cos(direction * math.pi / 2), -math.sin(direction * math.pi / 2)
    local is_obstacle_reached = false

    carriable:set_traversable_by("hero", true)
    carriable:set_direction(direction)
    sprite:set_xy(0, -22 + properties.vshift)

    -- Hit effects
    function hit_effects(carriable, entity)
      if not is_obstacle_reached then
        -- Call the hit_by_carriable() function if implemented by the entity
        if entity.hit_by_carriable then
          entity:hit_by_carriable(carriable)
          is_obstacle_reached = true
        end
        -- If the entity is an enemy, hurt it
        if entity:get_type() == "enemy" then
          entity:hurt(properties.hurt_damage)
          is_obstacle_reached = true
        end
        -- Stop the movement if a hit effect is triggered
        if is_obstacle_reached then
          carriable:stop_movement()
        end
      end
    end

    -- The collision test has to be setup for both touching and sprite collision mode to handle all cases
    -- Non-traversable entities need the touching collision while sprite collision is needed when entities are not on the same row nor column
    carriable:add_collision_test("sprite", hit_effects)
    carriable:add_collision_test("touching", hit_effects)

    -- Create a custom_entity for shadow (this one is drawn below).
    local px, py, pz = carriable:get_position()
    if properties.shadow_type then
      local shadow_properties = {x = px, y = py, layer = pz, direction = 0, width = 16, height = 16}
      shadow = map:create_custom_entity(shadow_properties)
      if properties.shadow_type == "normal" then
        shadow:create_sprite("entities/shadows/shadow")
        shadow:bring_to_back()
      end
      -- Remove shadow and/or traversable ground when the carriable is removed.
      function
        carriable:on_removed()
        shadow:remove()
      end
    end

    -- Function called when the carriable has fallen.
    function carriable:finish_bounce()
      carriable:clear_collision_tests()
      carriable:set_traversable_by("hero", false)
      avoid_overlap_with_hero(carriable) -- TODO wait for setting the carriable not traversable by hero instead
      if shadow then
        shadow:remove()
      end
      if carriable.on_finish_throw then
        carriable:on_finish_throw()
      end
    end
      
    -- Function to bounce when carriable is thrown.
    function carriable:bounce()
      -- Finish bouncing if we have already done all bounces.
      if current_bounce > properties.num_bounces then 
        carriable:finish_bounce()    
        return
      end  
      -- Initialize parameters for the bounce.
  	  local x, y, z
      local _, sy = sprite:get_xy()
      local dist = properties.bounce_distances[current_bounce]
      local h = properties.bounce_heights[current_bounce]
      if h == "same" then h = -sy end
      local dur = properties.bounce_durations[current_bounce]  
      local speed = 1000 * dist / dur -- Speed of the straight movement (pixels per second).
      local t = current_instant
      
      -- Function to compute height for each fall (bounce).
      function carriable:current_height()
        if current_bounce == 1 then return h * ((t / dur) ^ 2 - 1) end
        return 4 * h * ((t / dur) ^ 2 - t / dur)
      end
      -- Start straight movement if necessary. Stop movement for collisions with obstacle.
      if direction and not is_obstacle_reached then
        local movement = sol.movement.create("straight")
        movement:set_angle(direction * math.pi / 2)
        movement:set_speed(speed)
        movement:set_max_distance(dist)
        movement:set_smooth(true) -- TODO check for collision bugs when set to false
        movement:start(carriable)
      end
      
      -- Start shifting height of the carriable at each instant for current bounce.
      local refreshing_time = 5 -- Time between computations of each position.
      sol.timer.start(self, refreshing_time, function()
        t = t + refreshing_time
        current_instant = t
        if shadow then shadow:set_position(carriable:get_position()) end
        -- Update shift of sprite.
        if t <= dur then 
          sprite:set_xy(0, carriable:current_height() + properties.vshift)
        -- Stop the timer. Start next bounce or finish bounces. 
        else -- The carriable hits the ground.
          map:ground_collision(carriable, properties.bounce_sound) -- TODO Check for bad ground.
          -- Check if the carriable exists (it can be removed on holes, water and lava).
          if carriable:exists() then 
            if carriable.on_bounce then
              carriable:on_bounce(current_bounce)
            end
            current_bounce = current_bounce + 1
            current_instant = 0
            carriable:bounce() -- Start next bounce.
          end
          return false
        end
        return true
      end)
    end

    -- Start the bounces in the given direction.
    carriable:bounce()
  end)

  carriable:register_event("on_created", function(carriable)

    -- General properties
    local carriable_name = carriable:get_name()
    local carriable_model = carriable:get_model()
    carriable:set_traversable_by(false)
    carriable:set_drawn_in_y_order(true)
    carriable:set_weight(0)

    -- Traversable rules
    carriable:set_can_traverse_ground("deep_water", true)
    carriable:set_can_traverse_ground("shallow_water", true)
    carriable:set_can_traverse_ground("hole", true)
    carriable:set_can_traverse_ground("lava", true)
    carriable:set_can_traverse_ground("grass", true)
    carriable:set_can_traverse_ground("prickles", true)
    carriable:set_can_traverse_ground("low_wall", true)
    carriable:set_can_traverse("hero", true)
    carriable:set_can_traverse("stream", true)
    carriable:set_can_traverse("switch", true)
    carriable:set_can_traverse("teletransporter", true)
    carriable:set_can_traverse(false)

    -- Behavior when carried
    carriable:register_event("on_lifting", function(carriable, hero, carried_object)
      
      -- Remove the build-in carried object when thrown and replace it by the initial custom entity with custom thrown trajectory.
      carried_object:register_event("on_thrown", function(carried_object)

        local hero = map:get_hero()
        local x, y, layer = hero:get_position()
        local direction = hero:get_direction()
        local animation_set = carried_object:get_sprite():get_animation_set()
        local properties = {name = carriable_name, model = carriable_model,
            x = x, y = y, layer = layer, direction = direction, sprite = animation_set,
            width = 16, height = 16, sprite = animation_set}
        carried_object:remove()
        local thrown_carriable = map:create_custom_entity(properties)
        thrown_carriable:throw(direction)
      end)
    end)
  end)
end

return carriable_behavior