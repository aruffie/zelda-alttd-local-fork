-- The icon that shows what the action command does.

local hud_icon_builder = require("scripts/hud/hud_icon")

local action_icon_builder = {}

function action_icon_builder:new(game, config)

  local action_icon = {}

  -- Creates the hud icon delegate.
  action_icon.hud_icon = hud_icon_builder:new(config.x, config.y, config.dialog_x, config.dialog_y)
  action_icon.hud_icon:set_background_sprite(sol.sprite.create("hud/icon_action"))
  
  -- Initializes the icon.
  action_icon.text = sol.surface.create("action_icon_text.png", true) -- language specific
  action_icon.text_w, _ = action_icon.text:get_size()
  action_icon.text_h = 24
  action_icon.text_region_y = nil
  action_icon.effects_indexes = {
    ["validate"] = 1,
    ["next"] = 2,
    ["info"] = 3,
    ["return"] = 4,
    ["look"] = 5,
    ["open"] = 6,
    ["action"] = 7,
    ["lift"] = 8,
    ["throw"] = 9,
    ["grab"] = 10,
    ["stop"] = 11,
    ["speak"] = 12,
    ["change"] = 13,
    ["swim"] = 14,
    ["none"] = 15,
  }
  action_icon.effect_displayed = nil

  -- The surface used by the icon for the foreground is handled here.
  action_icon.foreground = sol.surface.create(action_icon.text_w, action_icon.text_h)
  action_icon.hud_icon:set_foreground(action_icon.foreground)
  
  -- Draws the icon surface.
  function action_icon:on_draw(dst_surface)
    action_icon.hud_icon:on_draw(dst_surface)
  end

  -- Rebuild the foreground (called only when needed).
  function action_icon:rebuild_foreground()
    action_icon.foreground:clear()

    action_icon.text_region_y = action_icon:get_region_y(action_icon.effect_displayed)
    if action_icon.text_region_y ~= nil then
      -- Draw the static image of the icon.
      action_icon.text:draw_region(0, action_icon.text_region_y, action_icon.text_w, action_icon.text_h, action_icon.foreground)
    end    
  end

  -- Set if the icon is enabled or disabled.
  function action_icon:set_enabled(enabled)
    if enabled then
      action_icon:update_effect_displayed(false)
    end
    action_icon.hud_icon:set_enabled(enabled)
  end
  
  -- Set if the icon is active or inactive.
  function action_icon:set_active(active)
    action_icon.hud_icon:set_active(active)
  end

  -- Gets the position of the icon.
  function action_icon:get_dst_position()
    return action_icon.hud_icon:get_dst_position()
  end

  -- Sets the position of the icon.
  function action_icon:set_dst_position(x, y)
    action_icon.hud_icon:set_dst_position(x, y)
  end

  -- Gets the normal position of the icon.
  function action_icon:get_normal_position()
    return action_icon.hud_icon:get_normal_position()
  end

  -- Gets the dialog position of the icon.
  function action_icon:get_dialog_position()
    return action_icon.hud_icon:get_dialog_position()
  end

  -- Computes the region to draw on the foreground.
  function action_icon:get_region_y(effect_displayed)
    local result = 0
    if action_icon.effect_displayed ~= nil and action_icon.effect_displayed ~= "" then
      result = action_icon.text_h * action_icon.effects_indexes[action_icon.effect_displayed]
    end
    return result
  end

  -- Called when the command effect changes.
  function action_icon:on_command_effect_changed(effect)
  end

  -- Checks if the icon needs a refresh.
  function action_icon:update_effect_displayed(flip_icon)
    if not action_icon.hud_icon.animating then
      local effect = game.get_custom_command_effect ~= nil and game:get_custom_command_effect("action") or game:get_command_effect("action")
      action_icon:set_effect_displayed(effect, flip_icon)
    end
  end

  -- Sets the effect to be displayed on the icon.
  function action_icon:set_effect_displayed(effect, flip_icon)
    if effect ~= action_icon.effect_displayed then
      -- Store the current command.
      action_icon.effect_displayed = effect
        
      -- Update the icon foreground.
      action_icon:rebuild_foreground()
      
      -- Flip the icon.
      if flip_icon then
        action_icon.hud_icon:flip_icon()
      end

      -- Update the icon visibility.
      if action_icon.on_command_effect_changed then
        action_icon:on_command_effect_changed(effect)
      end
    end
  end

  -- Called when the menu is started.
  function action_icon:on_started()
    action_icon:update_effect_displayed(false)

    -- Check every 50ms if the icon needs a refresh.
    sol.timer.start(action_icon, 50, function()
      action_icon:update_effect_displayed(true)
      return true
    end)
  end

  -- Returns the menu.
  return action_icon
end

return action_icon_builder
