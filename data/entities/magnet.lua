----------------------------------
--
-- An entity that can progressively attract another.
-- TODO This is basically a duplicate of a enemies/lib/common_actions.lua functions, factorize to entity meta one day.
--
-- Method : magnet:start_attracting(entity, speed, [moving_condition_callback])
--          magnet:stop_attracting([entity])
--
----------------------------------

local magnet = ...
local attracting_timers = {}
local trigonometric_functions = {math.cos, math.sin}

-- Start attracting the given entity, negative speed possible.
function magnet:start_attracting(entity, speed, ignore_obstacles, moving_condition_callback)

  -- Workaround : Don't use solarus movements to be able to start several movements at the same time.
  local move_ratio = speed > 0 and 1 or -1
  magnet:stop_attracting(entity)
  attracting_timers[entity] = {}

  local function attract_on_axis(axis)

    -- Clean if the entity was removed from outside.
    if not entity:exists() then
      magnet:stop_attracting(entity)
      return
    end

    local entity_position = {entity:get_position()}
    local magnet_position = {magnet:get_position()}
    local angle = math.atan2(entity_position[2] - magnet_position[2], magnet_position[1] - entity_position[1])
    
    local axis_move = {0, 0}
    local axis_move_delay = 10 -- Default timer delay if no move

    if not moving_condition_callback or moving_condition_callback() then

      -- Always move pixel by pixel.
      axis_move[axis] = math.max(-1, math.min(1, magnet_position[axis] - entity_position[axis])) * move_ratio
      if axis_move[axis] ~= 0 then

        -- Schedule the next move on this axis depending on the remaining distance and the speed value, avoiding too high and low timers.
        axis_move_delay = 1000.0 / math.max(1, math.min(100, math.abs(speed * trigonometric_functions[axis](angle))))

        -- Move the entity.
        if ignore_obstacles or not entity:test_obstacles(axis_move[1], axis_move[2]) then
          entity:set_position(entity_position[1] + axis_move[1], entity_position[2] + axis_move[2], entity_position[3])
        end
      end
    end

    -- Start the next pixel move timer.
    attracting_timers[entity][axis] = sol.timer.start(magnet, axis_move_delay, function()
      attract_on_axis(axis)
    end)
  end

  attract_on_axis(1)
  attract_on_axis(2)
end

 -- Stop looped timers related to the attractions.
function magnet:stop_attracting(entity)

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
