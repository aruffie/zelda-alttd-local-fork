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


--shake while following an entity
function camera_meta:dynamic_shake(config, callback)

  local shaking_count_max = config ~= nil and config.count or 9
  local amplitude = config ~= nil and config.amplitude or 4
  local entity = config ~= nil and config.entity or self:get_map():get_hero()

  local camera = self
  local map = camera:get_map()

  local shaking_to_right = true
  local shaking_count = 0
  local offset_x=0
  local offset_y=0

  local w,h=camera:get_size()

  local function clamp(val, min, max)
    return math.max(min, math.min(val, max))
  end

  local function get_region_bounding_box(map,x,y)
    --By default, make the region bounding box match the map's
    local bx1=0
    local by1=0
    local bx2, by2=map:get_size()
    -- Then, shrink bounding box to actual region size by comparing with the separators; if any.
    for e in map:get_entities_in_region(x,y) do
      if e:get_type()=="separator" then
        local ex,ey, ew, eh=e:get_bounding_box()
        if ew>eh then --Horizontal separator
          if y>ey then
            by1=math.max(by1, ey+8)
          else
            by2=math.min(by2, ey+8)  
          end
        else
          if x>ex then
            bx1=math.max(bx1, ex+8)
          else
            bx2=math.min(bx2, ex+8)
          end
        end
      end
    end
    return bx1, by1, bx2, by2
  end
  local x_min, y_min, x_max, y_max=get_region_bounding_box(map, entity:get_position())

  local function shake_step()

    -- Determine the shifting offset (maybe shift according to a given direction in the future?)
    if shaking_to_right then
      offset_x = amplitude/2 -- Right.
      offset_y = amplitude/2 
    else
      offset_x = -amplitude/2 -- Left.
      offset_y = -amplitude/2
    end

    local ex, ey, ew, eh=entity:get_bounding_box()

    camera:set_position(clamp(ex+ew/2-w/2+offset_x, x_min-amplitude/2, x_max-w+amplitude/2), clamp(ey+ew/2-h/2+offset_y, y_min-amplitude/2, y_max-h+amplitude/2))

    -- Inverse direction for next time.
    shaking_to_right = not shaking_to_right
    shaking_count = shaking_count + 1

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
