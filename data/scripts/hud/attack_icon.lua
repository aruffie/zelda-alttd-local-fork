-- The icon that shows what the attack command does.

local hud_icon_builder = require("scripts/hud/hud_icon")

local attack_icon_builder = {}

function attack_icon_builder:new(game, config)

  local attack_icon = {}

  -- Creates the hud icon delegate.
  attack_icon.hud_icon = hud_icon_builder:new(config.x, config.y, config.dialog_x, config.dialog_y)
  attack_icon.hud_icon:set_background_sprite(sol.sprite.create("hud/icon_attack"))
  
  -- Initializes the icon.
  attack_icon.text = sol.surface.create("attack_icon_text.png", true) -- language specific
  attack_icon.text_w, _ = attack_icon.text:get_size()
  attack_icon.text_h = 24
  attack_icon.text_region_y = nil
  attack_icon.effects_indexes = {
    ["save"] = 1,
    ["return"] = 2,
    ["validate"] = 3,
    ["skip"] = 4,
  }
  attack_icon.effect_displayed = nil
  attack_icon.sword_displayed = nil
  
  -- The surface used by the icon for the foreground is handled here.
  attack_icon.foreground = sol.surface.create(attack_icon.text_w, attack_icon.text_h)
  attack_icon.hud_icon:set_foreground(attack_icon.foreground)
  
  -- Draws the icon surface.
  function attack_icon:on_draw(dst_surface)
    attack_icon.hud_icon:on_draw(dst_surface)
  end

  -- Rebuild the foreground (called only when needed).
  function attack_icon:rebuild_foreground()
    attack_icon.foreground:clear()

    attack_icon.text_region_y = attack_icon:get_region_y(attack_icon.effect_displayed, attack_icon.sword_displayed)
    if attack_icon.text_region_y ~= nil then
      -- Draw the static image of the icon.
      attack_icon.text:draw_region(0, attack_icon.text_region_y, attack_icon.text_w, attack_icon.text_h, attack_icon.foreground)
    end    
  end

  -- Set if the icon is enabled or disabled.
  function attack_icon:set_enabled(enabled)
    attack_icon.hud_icon:set_enabled(enabled)
  end
  
  -- Set if the icon is active or inactive.
  function attack_icon:set_active(active)
    attack_icon.hud_icon:set_active(active)
  end

  -- Gets the position of the icon.
  function attack_icon:get_dst_position()
    return attack_icon.hud_icon:get_dst_position()
  end

  -- Sets the position of the icon.
  function attack_icon:set_dst_position(x, y)
    attack_icon.hud_icon:set_dst_position(x, y)
  end

  -- Gets the normal position of the icon.
  function attack_icon:get_normal_position()
    return attack_icon.hud_icon:get_normal_position()
  end

  -- Gets the dialog position of the icon.
  function attack_icon:get_dialog_position()
    return attack_icon.hud_icon:get_dialog_position()
  end

  -- Computes the region to draw on the foreground.
  function attack_icon:get_region_y(effect_displayed, sword_displayed)
    local result = 0
    if attack_icon.effect_displayed ~= nil then
      if attack_icon.effect_displayed == "sword" then
        -- Create an icon with the current sword.
        result = (4 * attack_icon.text_h) + attack_icon.text_h * attack_icon.sword_displayed
      elseif attack_icon.effect_displayed ~= nil and attack_icon.effect_displayed ~= "" then
        -- Create an icon with the name of the current effect.
        result = attack_icon.text_h * attack_icon.effects_indexes[attack_icon.effect_displayed]
      end
    end
    return result
  end

  -- Checks if the icon needs a refresh.
  function attack_icon:check()
    local effect = game.get_custom_command_effect ~= nil and game:get_custom_command_effect("attack") or game:get_command_effect("attack")
    local sword = game:get_ability("sword")
    if effect ~= attack_icon.effect_displayed or sword ~= attack_icon.sword_displayed then
      -- Store the current commands to display on the icon.
      attack_icon.effect_displayed = effect
      attack_icon.sword_displayed = sword

      attack_icon.hud_icon:flip_icon(function()
        -- Redraw the surface.
        attack_icon:rebuild_foreground()
      end)

    end

    -- Schedule the next check.
    sol.timer.start(attack_icon, 50, function()
      attack_icon:check()
    end)
  end

  -- Called when the menu is started.
  function attack_icon:on_started()
    attack_icon:check()
  end

  -- Returns the menu.
  return attack_icon
end

return attack_icon_builder
