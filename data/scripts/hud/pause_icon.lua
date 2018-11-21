-- The icon that shows what the pause command does.

local hud_icon_builder = require("scripts/hud/hud_icon")

local pause_icon_builder = {}

function pause_icon_builder:new(game, config)

  local pause_icon = {}

  -- Creates the hud icon delegate.
  pause_icon.hud_icon = hud_icon_builder:new(config.x, config.y)
  pause_icon.hud_icon:set_background_sprite(sol.sprite.create("hud/icon_pause"))

  -- Initializes the icon.
  pause_icon.text = sol.surface.create("pause_icon_text.png", true) -- language specific
  pause_icon.text_w, _ = pause_icon.text:get_size()
  pause_icon.text_h = 24
  pause_icon.text_region_y = nil
  
  -- The surface used by the icon for the foreground is handled here.
  pause_icon.foreground = sol.surface.create(pause_icon.text_w, pause_icon.text_h)
  pause_icon.hud_icon:set_foreground(pause_icon.foreground)

  -- Draws the icon surface.
  function pause_icon:on_draw(dst_surface)
    pause_icon.hud_icon:on_draw(dst_surface)
  end

  -- Rebuild the foreground (called only when needed).
  function pause_icon:rebuild_foreground()
    -- Compute the region to draw.
    local text_region_y = pause_icon.text_h * (game:is_paused() and 2 or 1)

    -- Update the surface only if needed.
    if text_region_y ~= pause_icon.text_region_y then
      pause_icon.text_region_y = text_region_y
      pause_icon.foreground:clear()
      pause_icon.text:draw_region(0, text_region_y, pause_icon.text_w, pause_icon.text_h, pause_icon.foreground, 0, 0)
    end
  end
  
  -- Set if the icon is enabled or disabled.
  function pause_icon:set_enabled(enabled)
    pause_icon.hud_icon:set_enabled(enabled)
  end
  
  -- Set if the icon is active or inactive.
  function pause_icon:set_active(active)
    pause_icon.hud_icon:set_active(active)
  end

  -- Called when the menu is started.
  function pause_icon:on_started()
    pause_icon:rebuild_foreground()    
  end

  -- Listens to the on_paused event, to update the text.
  game:register_event("on_paused", function()
    pause_icon.hud_icon:flip_icon(function()
      pause_icon:rebuild_foreground()
    end)
  end)
  
  -- Listens to the on_unpaused event, to update the text.
  game:register_event("on_unpaused", function()
    pause_icon.hud_icon:flip_icon(function()
      pause_icon:rebuild_foreground()
    end)
  end)

  -- Returns the menu.
  return pause_icon
end

return pause_icon_builder
