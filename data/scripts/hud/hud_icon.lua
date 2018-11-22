-- Generic icon script.

local hud_icon_builder = {}

function hud_icon_builder:new(icon_x, icon_y, dialog_icon_x, dialog_icon_y)  
  local hud_icon = {}
  hud_icon.x, hud_icon.y = icon_x, icon_y

  -- Save
  hud_icon.normal_x, hud_icon.normal_y = icon_x, icon_y
  hud_icon.dialog_x, hud_icon.dialog_y = dialog_icon_x, dialog_icon_y

  -- Initialize layers.
  hud_icon.surface = nil
  hud_icon.background_sprite = nil
  hud_icon.foreground = nil
  
  -- Initialize state.
  hud_icon.enabled = true
  hud_icon.active = true
  hud_icon.animating = false

  -- Returns if the icon is active or not.
  function hud_icon:is_active()
    return hud_icon.active
  end

  -- Sets if the icon is active or not.
  function hud_icon:set_active(active)
    if active ~= hud_icon.active then
      hud_icon.active = active
    end
  end

  -- Returns if the icon is enabled or not.
  function hud_icon:is_enabled()
    return hud_icon.enabled
  end

  -- Sets if the icon is enabled or not.
  function hud_icon:set_enabled(enabled)
    if enabled ~= hud_icon.enabled then
      hud_icon.enabled = enabled
      
      -- Flip the icon.
      if enabled then
        if hud_icon.background_sprite ~= nil then
          hud_icon.animating = true
          hud_icon.background_sprite:set_animation("appearing", function()
            hud_icon.background_sprite:set_animation("visible")
            hud_icon.animating = false
          end)
        else
          hud_icon.animating = false
        end
      else
        if hud_icon.background_sprite ~= nil then
          hud_icon.animating = true
          hud_icon.background_sprite:set_animation("disappearing", function()
            hud_icon.background_sprite:set_animation("invisible")
            hud_icon.animating = false
          end)
        else
          hud_icon.animating = false
        end
      end
    end
  end

  -- Draws the icon.
  function hud_icon:on_draw(dst_surface)
    -- Draw only if needed.
    if hud_icon.enabled or hud_icon.animating then
      -- Update the surface if the foreground or the background size have changed since last draw.
      hud_icon:update_surface_if_needed()

      -- Draw only if the surface previously created has a valid size.
      if hud_icon.surface ~= nil then
        -- Compute position.
        local x, y = hud_icon.x, hud_icon.y
        local width, height = dst_surface:get_size()
        if x < 0 then
          x = width + x
        end
        if y < 0 then
          y = height + y
        end
  
        -- Coordinates of the center, in dst_surface coordinate system.
        local center_x, center_y = x + hud_icon.background_w / 2, y + hud_icon.background_h / 2

        -- Coordinates of the surface, in dst_surface coordinate system.
        local surface_x, surface_y = center_x - hud_icon.surface_w / 2, center_y - hud_icon.surface_h / 2

        -- Clear the surface.
        hud_icon.surface:clear()
  
        -- Background.
        if hud_icon.background_sprite ~= nil then
          -- Coordinates of the background, in hud_icon.surface coordinates system.
          local background_x, background_y = (hud_icon.surface_w - hud_icon.background_w) / 2, (hud_icon.surface_h - hud_icon.background_h) / 2
          
          -- Draw the background on temp surface.
          hud_icon.background_sprite:draw(hud_icon.surface, background_x, background_y)
        end
  
        -- Foreground.
        if not hud_icon.animating and hud_icon.foreground ~= nil then
          -- Coordinates of the foreground, in hud_icon.surface coordinates system.
          local foreground_x, foreground_y = (hud_icon.surface_w - hud_icon.foreground_w) / 2, (hud_icon.surface_h - hud_icon.foreground_h) / 2
          -- Draw the background on temp surface.
          hud_icon.foreground:draw(hud_icon.surface, foreground_x, foreground_y)
        end
  
        -- Active/inactive state.
        if hud_icon.active then
          hud_icon.surface:set_opacity(255)
        else
          hud_icon.surface:set_opacity(128)
        end
        
        -- Draw the surface.
        hud_icon.surface:draw(dst_surface, surface_x, surface_y)
      end
    end
  end

  -- Flips the icon to display the new foreground.
  function hud_icon:flip_icon(callback)
    if hud_icon.enabled then
      hud_icon.animating = true
      if hud_icon.background_sprite ~= nil then
        hud_icon.background_sprite:set_animation("flipping", function()
          hud_icon.background_sprite:set_animation("visible")
          hud_icon.animating = false
  
          -- Callback called when finished.
          if callback ~= nil then
            callback()
          end
        end)
      end
    end
  end

  -- Sets the foreground drawn above the icon sprite.
  function hud_icon:set_background_sprite(sprite)
    if hud_icon.background_sprite ~= sprite then
      -- Update background size.
      if sprite ~= nil then
        hud_icon.background_w, hud_icon.background_h = sprite:get_size()
      else
        hud_icon.background_w, hud_icon.background_h = 0, 0
      end
      -- Update sprite.
      hud_icon.background_sprite = sprite
    end
  end

  -- Gets the foreground drawn above the icon sprite.
  function hud_icon:get_background_sprite()
    return hud_icon.background_sprite
  end

  -- Sets the foreground drawn above the icon sprite.
  function hud_icon:set_foreground(foreground)
    if hud_icon.foreground ~= foreground then
      -- Update foreground size.
      if foreground ~= nil then
        hud_icon.foreground_w, hud_icon.foreground_h = foreground:get_size()
      else
        hud_icon.foreground_w, hud_icon.foreground_h = 0, 0
      end

      -- Update foreground.
      hud_icon.foreground = foreground
    end
  end

  -- Gets the foreground drawn above the icon sprite.
  function hud_icon:get_foreground()
    return hud_icon.foreground
  end

  -- Compares the foreground size to the current surface size and
  -- updates the later if needed.
  function hud_icon:update_surface_if_needed()
    local new_surface_w = math.max(hud_icon.background_w, hud_icon.foreground_w)
    local new_surface_h = math.max(hud_icon.background_h, hud_icon.foreground_h)
    
    local old_surface_w, old_surface_h = 0, 0
    if hud_icon.surface ~= nil then
      old_surface_w, old_surface_h = hud_icon.surface:get_size()
    end

    if new_surface_h == 0 or new_surface_w == 0 then
      hud_icon.surface = nil
      hud_icon.surface_w, hud_icon.surface_h = 0, 0
    elseif new_surface_h ~= old_surface_h or new_surface_w ~= old_surface_w then
      hud_icon.surface = sol.surface.create(new_surface_w, new_surface_h)
      hud_icon.surface_w, hud_icon.surface_h = new_surface_w, new_surface_h
    end
  end

  -- Gets the position of the icon.
  function hud_icon:get_dst_position()
    return hud_icon.x, hud_icon.y
  end

  -- Sets the position of the icon.
  function hud_icon:set_dst_position(x, y)
    hud_icon.x, hud_icon.y = x, y
  end

  -- Gets the normal position of the icon.
  function hud_icon:get_normal_position()
    return hud_icon.normal_x, hud_icon.normal_y
  end

  -- Gets the dialog position of the icon.
  function hud_icon:get_dialog_position()
    return hud_icon.dialog_x, hud_icon.dialog_y
  end

  return hud_icon
end

return hud_icon_builder
