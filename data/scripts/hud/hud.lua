-- Script that creates a head-up display for a game.

-- Usage:
-- require("scripts/hud/hud")

require("scripts/multi_events")
local hud_config = require("scripts/hud/hud_config")

-- Creates and runs a HUD for the specified game.
local function initialize_hud_features(game)

  if game.set_hud_enabled ~= nil then
    -- If the initialization is already done, just display the HUD.
    game:set_hud_mode("normal")
    game:set_hud_enabled(true)
    return
  end

  -- Sets up the HUD.
  local hud = {
    enabled = false,
    elements = {},
    showing_dialog = false,
    top_left_opacity = 255,
    custom_command_effects = {},
  }

  -- For quicker and direct access to the icons.
  local item_icons = {}
  local action_icon
  local attack_icon
  local pause_icon

  -----------------------------------------------------------------------------
  -- Game functions.
  -----------------------------------------------------------------------------

  -- Returns the game's HUD.
  function game:get_hud()
    return hud
  end

  -- Returns whether the HUD is currently shown.
  function game:is_hud_enabled()
    return hud:is_enabled()
  end

  -- Enables or disables the HUD.
  function game:set_hud_enabled(enabled)
    return hud:set_enabled(enabled)
  end

  -- Returns the custom command effect for the command.
  function game:get_custom_command_effect(command)
    return hud.custom_command_effects[command]
  end

  -- Make the action (or attack) icon of the HUD show something else than the
  -- built-in effect or the action (or attack) command.
  -- You are responsible to override the command if you don't want the built-in
  -- effect to be performed.
  -- Set the effect to nil to show the built-in effect again.
  function game:set_custom_command_effect(command, effect)
    hud.custom_command_effects[command] = effect
  end

  -- Ensures the HUD is above evrything.
  function game:bring_hud_to_front()
    if game.get_hud ~= nil then
      local hud = game:get_hud()
      if hud ~= nil then
        hud:bring_icons_to_front()
      end
    end
  end

  -- Only shows basic HUD when in dialog mode.
  function game:set_hud_mode(mode)
    if game.get_hud ~= nil then
      local hud = game:get_hud()
      if hud ~= nil then
        hud:set_mode(mode)
      end
    end
  end  

  -- Returns the HUD mode.
  function game:get_hud_mode()
    if game.get_hud ~= nil then
      local hud = game:get_hud()
      if hud ~= nil then
        return hud:get_mode()
      end
    end
    return nil
  end  

 -----------------------------------------------------------------------------
  -- HUD functions.
  -----------------------------------------------------------------------------

  -- Destroys the HUD.
  function hud:quit()
    if hud:is_enabled() then
      -- Stop all HUD elements.
      hud:set_enabled(false)
    end
  end

  -- Call this function to notify the HUD that the current map has changed.
  local function hud_on_map_changed(game, map)
    if hud:is_enabled() then
      for _, menu in ipairs(hud.elements) do
        if menu.on_map_changed ~= nil then
          menu:on_map_changed(map)
        end
      end
    end
  end

  -- Call this function to notify the HUD that the game was just paused.
  local function hud_on_paused(game)
    if hud:is_enabled() then
      for _, menu in ipairs(hud.elements) do
        if menu.on_paused ~= nil then
          menu:on_paused()
        end
      end
    end
  end

  -- Call this function to notify the HUD that the game was just unpaused.
  local function hud_on_unpaused(game)
    if hud:is_enabled() then
      for _, menu in ipairs(hud.elements) do
        if menu.on_unpaused ~= nil then
          menu:on_unpaused()
        end
      end
    end
  end

  -- Call this function to notify the HUD that a dialog was just started.
  local function hud_on_dialog_started(game, dialog, info)
    hud.backup_mode = hud:get_mode()
    hud:set_mode("dialog")

    -- if hud:is_enabled() then
    --   for _, menu in ipairs(hud.elements) do
    --     if menu.on_dialog_started ~= nil then
    --       menu:on_dialog_started()
    --     end
    --   end
    -- end
  end

  -- Call this function to notify the HUD that a dialog was just finished.
  local function hud_on_dialog_finished(game, dialog, info)
    local old_mode = hud.backup_mode ~= nil and hud.backup_mode or "normal" 
    hud:set_mode(old_mode)
    hud.backup_mode = nil

    -- if hud:is_enabled() then
    --   for _, menu in ipairs(hud.elements) do
    --     if menu.on_dialog_finished ~= nil then
    --       menu:on_dialog_finished()
    --     end
    --   end
    -- end
  end

  -- Called periodically to change the transparency or position of icons.
  local function check_hud()
    if not hud:is_enabled() then
      return true
    end

    local map = game:get_map()
    if map ~= nil then
      -- If the hero is below the top-left icons, make them semi-transparent.
      local hero = map:get_entity("hero")
      local hero_x, hero_y = hero:get_position()
      local camera_x, camera_y = map:get_camera():get_position()
      local x = hero_x - camera_x
      local y = hero_y - camera_y
      local opacity = nil

      if hud.top_left_opacity == 255 and not game:is_suspended() and x < 88 and y < 80 then
        opacity = 96
      elseif hud.top_left_opacity == 96 and (game:is_suspended() or x >= 88 or y >= 80) then
        opacity = 255
      end

      if opacity ~= nil then
        hud.top_left_opacity = opacity
        for i, element_config in ipairs(hud_config) do
          if element_config.x >= 0 and element_config.x < 72 and
              element_config.y >= 0 and element_config.y < 64 then
            hud.elements[i]:get_surface():set_opacity(opacity)
          end
        end
      end
    end

    return true  -- Repeat the timer.
  end

  -- Returns the HUD current mode.
  function hud:get_mode()
    return hud.mode
  end

  -- Sets the mode of the HUD ("normal"-by default, "dialog", "pause" or "no_buttons").
  -- The icons adapt themselves to this mode.
  -- Ex: During a dialog, move the action icon and the sword icon, and hides the
  -- item icons.
  function hud:set_mode(mode)
    if mode ~= hud.mode then
      if mode == "dialog" then
        hud.mode = mode

        if attack_icon ~= nil then
          attack_icon:set_dst_position(attack_icon:get_dialog_position())
          local effect = game.get_custom_command_effect ~= nil and game:get_custom_command_effect("attack") or game:get_command_effect("attack")
          attack_icon:set_enabled(effect ~= nil)
        end

        if action_icon ~= nil then
          action_icon:set_dst_position(action_icon:get_dialog_position())
          local effect = game.get_custom_command_effect ~= nil and game:get_custom_command_effect("action") or game:get_command_effect("action")
          action_icon:set_enabled(effect ~= nil)
        end

        if pause_icon ~= nil then
          pause_icon:set_enabled(false)
        end

        for _, item_icon in ipairs(item_icons) do
          if item_icon ~= nil then
            item_icon:set_active(false)
            item_icon:set_enabled(false)
          end
        end
      elseif mode == "pause" then
        hud.mode = mode

        if attack_icon ~= nil then
          attack_icon:set_dst_position(attack_icon:get_normal_position())
          local effect = game.get_custom_command_effect ~= nil and game:get_custom_command_effect("attack") or game:get_command_effect("attack")
          attack_icon:set_enabled(effect ~= nil)
        end

        if action_icon ~= nil then
          action_icon:set_dst_position(action_icon:get_normal_position())
          local effect = game.get_custom_command_effect ~= nil and game:get_custom_command_effect("action") or game:get_command_effect("action")
          action_icon:set_enabled(effect ~= nil)
        end

        if pause_icon ~= nil then
          pause_icon:set_enabled(true)
        end

        for _, item_icon in ipairs(item_icons) do
          if item_icon ~= nil then
            item_icon:set_active(false)
            item_icon:set_enabled(true)
          end
        end
      elseif mode == "normal" then
        hud.mode = mode

        if attack_icon ~= nil then
          attack_icon:set_dst_position(attack_icon:get_normal_position())
          local effect = game.get_custom_command_effect ~= nil and game:get_custom_command_effect("attack") or game:get_command_effect("attack")
          attack_icon:set_enabled(effect ~= nil)
        end

        if action_icon ~= nil then
          action_icon:set_dst_position(action_icon:get_normal_position())
          local effect = game.get_custom_command_effect ~= nil and game:get_custom_command_effect("action") or game:get_command_effect("action")
          action_icon:set_enabled(effect ~= nil)
        end

        if pause_icon ~= nil then
          pause_icon:set_enabled(true)
        end
        
        for _, item_icon in ipairs(item_icons) do
          if item_icon ~= nil then
            item_icon:set_active(true)
            item_icon:set_enabled(true)
          end
        end
      elseif mode == "no_buttons" then
        hud.mode = mode
        
        if attack_icon ~= nil then
          attack_icon:set_dst_position(attack_icon:get_normal_position())
          attack_icon:set_enabled(false)        
        end

        if action_icon ~= nil then
          action_icon:set_dst_position(action_icon:get_normal_position())
          action_icon:set_enabled(false)        
        end

        if pause_icon ~= nil then
          pause_icon:set_enabled(false)
        end
        
        for _, item_icon in ipairs(item_icons) do
          if item_icon ~= nil then
            item_icon:set_active(false)
            item_icon:set_enabled(false)
          end
        end
      else
        print("HUD mode is not supported: "..mode)
        hud:set_mode("normal") --fallback
      end
    end
  end

  -- Returns whether the HUD is currently enabled (i.e. visible).
  function hud:is_enabled()
    return hud.enabled
  end

  -- Enables or disables the HUD.
  function hud:set_enabled(enabled)
    if enabled ~= hud.enabled then
      hud.enabled = enabled

      for _, menu in ipairs(hud.elements) do
        if enabled then
          if not sol.menu.is_started(menu) then
            -- Start each HUD element.
            sol.menu.start(game, menu)
          end
        else
          -- Stop each HUD element.
          sol.menu.stop(menu)
        end
      end

      -- Bring to front.
      if enabled then
        hud:bring_to_front()
      end
    end
  end

  -- Changes the opacity of an item icon
  -- Active means full opacity, and not active means half opacity.
  function hud:set_item_icon_active(item_index, is_active)
    item_icons[item_index].set_active(is_active)
  end
  
  -- Brings the whole HUD to the front.
  function hud:bring_to_front()
    for _, menu in ipairs(hud.elements) do
      sol.menu.bring_to_front(menu)
    end
  end

  -- Brings only the icons of the HUD to the front.
  function hud:bring_icons_to_front()
    sol.menu.bring_to_front(attack_icon)
    sol.menu.bring_to_front(action_icon)
    sol.menu.bring_to_front(pause_icon)
    for _, item_icon in ipairs(item_icons) do
     sol.menu.bring_to_front(item_icon)
    end
  end

  -- Retrieves the elements and stores them for quicker access.
  for _, element_config in ipairs(hud_config) do
    local element_builder = require(element_config.menu_script)
    local element = element_builder:new(game, element_config)
    if element.set_dst_position ~= nil then
      -- Compatibility with old HUD element scripts
      -- whose new() method does not take a config parameter.
      element:set_dst_position(element_config.x, element_config.y)
    end
    hud.elements[#hud.elements + 1] = element

    if element_config.menu_script == "scripts/hud/item_icon" then
      item_icons[element_config.slot] = element
    elseif element_config.menu_script == "scripts/hud/action_icon" then
      action_icon = element
      -- Reacts to a change in the effect displayed by the icon.
      function action_icon:on_command_effect_changed(effect)
        action_icon:set_enabled(hud:get_mode() ~= "no_buttons" and effect ~= nil)
      end
    elseif element_config.menu_script == "scripts/hud/attack_icon" then
      attack_icon = element
      -- Reacts to a change in the effect displayed by the icon.
      function attack_icon:on_command_effect_changed(effect)
        attack_icon:set_enabled(hud:get_mode() ~= "no_buttons" and effect ~= nil)
      end
    elseif element_config.menu_script == "scripts/hud/pause_icon" then
      pause_icon = element
    end
  end

  -- Listens to the events on game, and reacts accordingly.
  game:register_event("on_map_changed", hud_on_map_changed)
  game:register_event("on_paused", hud_on_paused)
  game:register_event("on_unpaused", hud_on_unpaused)
  --game:register_event("on_dialog_started", hud_on_dialog_started)
  --game:register_event("on_dialog_finished", hud_on_dialog_finished)

  -- Start the HUD.
  hud:set_enabled(true)
  hud:set_mode("normal")
  --sol.timer.start(game, 50, check_hud) -- TODO
end

-- Set up the HUD features on any game that starts.
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", initialize_hud_features)

return true
