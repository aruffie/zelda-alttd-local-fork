-- Provides additional camera features for this quest.

-- Variables
local camera_meta = sol.main.get_metatable("camera")

function camera_meta:shake(config, callback)

  local shaking_count_max = config ~= nil and config.count or 9
  local amplitude = config ~= nil and config.amplitude or 4
  local speed = config ~= nil and config.speed or 60

  local camera = self
  local map = camera:get_map()
  local hero = map:get_hero()

  local shaking_to_right = true
  local shaking_count = 0

  local function shake_step()

    local movement = sol.movement.create("straight")
    movement:set_speed(speed)
    movement:set_smooth(false)
    movement:set_ignore_obstacles(true)

    -- Determine direction.
    if shaking_to_right then
      movement:set_angle(0)  -- Right.
    else
      movement:set_angle(math.pi)  -- Left.
    end

    -- Max distance.
    movement:set_max_distance(amplitude)

    -- Inverse direction for next time.
    shaking_to_right = not shaking_to_right
    shaking_count = shaking_count + 1

    -- Launch the movement and repeat if needed.
    movement:start(camera, function()

        -- Repeat shaking until the count_max is reached.
        if shaking_count <= shaking_count_max then
          -- Repeat shaking.
          shake_step()
        else
          -- Finished.
          camera:start_tracking(hero)
          if callback ~= nil then
            callback()
          end
        end
      end)
  end

  shake_step()

end

function camera_meta:dynamic_shake(config, callback)

  local shaking_count_max = config ~= nil and config.count or 9
  local amplitude = config ~= nil and config.amplitude or 4
  local speed = config ~= nil and config.speed or 60
  local entity = config ~= nil and config.entity or self:get_map():get_hero()

  local camera = self
  local map = camera:get_map()

  local shaking_to_right = true
  local shaking_count = 0
  local offset_x=0
  local offset_y=0

  local w,h=camera:get_size()

  local mw, mh=map:get_size()

  local function clamp(val, min, max)
    return math.max(min, math.min(val, max))
  end

  local function shake_step()

--    local movement = sol.movement.create("target")
--    movement:set_speed(speed)
--    movement:set_target(entity, offset_x-ox+ew/2-w/2, offset_y-oy+eh/2-h/2)
--    movement:set_smooth(false)
--    movement:set_ignore_obstacles(true)
    local ex, ey, ew, eh=entity:get_bounding_box()

    camera:set_position(clamp(ex+ew/2-w/2+offset_x, -amplitude/2, mw-w+amplitude/2), clamp(ey+ew/2-h/2+offset_y, -amplitude/2, mh-h+amplitude/2))
    -- Determine direction.
    if shaking_to_right then
      offset_x = amplitude/2 -- Right.
      offset_y = amplitude/2 
    else
      offset_x = -amplitude/2 -- Left.
      offset_y = -amplitude/2
    end

    -- Inverse direction for next time.
    shaking_to_right = not shaking_to_right
    shaking_count = shaking_count + 1

    -- Launch the movement and repeat if needed.
--    movement:start(camera, function()

    -- Repeat shaking until the count_max is reached.
    if shaking_count <= shaking_count_max then
      -- Repeat shaking.
      return true
    else
      -- Finished.
      camera:start_tracking(entity)
      if callback ~= nil then
        callback()
      end
    end
--      end)
  end
  sol.timer.start(camera, 10, shake_step)

end

return true
