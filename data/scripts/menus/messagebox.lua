-- Simple message box dialog.

local language_manager = require("scripts/language_manager")
local game_manager = require("scripts/game_manager")

local messagebox_builder = {}

function messagebox_builder:show(context, text_lines, button_1_text, button_2_text, default_button_index, callback)
  
  -- Creates the menu.
  local messagebox_menu = {}

  function messagebox_menu:on_started()
    -- Fix the font shift (issue with Minecraftia)
    self.font_y_shift = -1

    -- Create static surfaces.
    self.frame_img = sol.surface.create("menus/messagebox/messagebox_frame.png")
    local frame_w, frame_h = self.frame_img:get_size()
    self.surface = sol.surface.create(frame_w, frame_h)
    self.button_img = sol.surface.create("menus/messagebox/messagebox_button.png")

    -- Create sprites.
    self.cursor_sprite = sol.sprite.create("menus/messagebox/messagebox_cursor")

    -- Get fonts.
    local menu_font, menu_font_size = language_manager:get_menu_font()
    self.menu_font = menu_font
    self.menu_font_size = menu_font_size
    self.text_color = { 115, 59, 22 }
    self.text_color_light = { 177, 146, 116 }

    -- Elements positions relative to self.surface.
    self.button_2_x = 136
    self.button_y = frame_h - 28
    self.cursor_x = 0
    self.cursor_y = 0
    self.text_y = 16

    -- Prepare texts.
    self.text_lines = {}
    for i = 1, 3 do
      local text_line = sol.text_surface.create{
        color = self.text_color,
        font = self.menu_font,
        font_size = self.menu_font_size,
        horizontal_alignment = "center",
      }
      self.text_lines[i] = text_line
    end

    self.buttons = {}  
    self.buttons[1] = { 
      x = 24,
      text = sol.text_surface.create{
        color = self.text_color,
        font = self.menu_font,
        font_size = self.menu_font_size,
        horizontal_alignment = "center",
      }
    }
    self.buttons[2] = {
      x = 136,
      text = sol.text_surface.create{
        color = self.text_color,
        font = self.menu_font,
        font_size = self.menu_font_size,
        horizontal_alignment = "center",
      }
    }
    self.button_count = 2

    -- Callback when the menu is done.
    self.callback = function(result)
    end

    -- We handle command bindings manually because of the order of events in 1.6.
    self.command_bindings = { 
      ["action"] = "",
      ["attack"] = "",
      ["left"] = "",
      ["right"] = "",
      ["pause"] = "",
    }
    
    local function invert_table(t)
      local s = {}
      for k, v in pairs(t) do
        s[v] = k
      end
      return s
    end

    local game = sol.main.game
    if game ~= nil then
      -- Retrieve the keyboard bindings.
      for key, _  in pairs(self.command_bindings) do
        self.command_bindings[key] = game:get_command_keyboard_binding(key)
      end
      -- Invert the table for better performance when looking for a key.
      self.command_bindings = invert_table(self.command_bindings)

      -- Custom commands effects
      if game.set_custom_command_effect ~= nil then
        -- Backup the current actions.
        self.backup_actions = {
          ["action"] = "",
          ["attack"] = "",
        }
        for key, _  in pairs(self.backup_actions) do
          self.backup_actions[key] = game:get_custom_command_effect(key)
        end

        -- Set the new ones.
        local new_actions = {
          ["action"] = "validate",
          ["attack"] = "return",
        }
        for key, value in pairs(new_actions) do
          game:set_custom_command_effect(key, value)
        end
      
      else
        self.backup_actions = {
          ["action"] = "",
          ["attack"] = "",
        }
      end

      -- Set the HUD on top.
      game:bring_hud_to_front()

      -- Set the correct HUD mode.
      self.backup_hud_mode = game:get_hud_mode()
      game:set_hud_mode("dialog")
    else
      self.backup_actions = {
        ["action"] = "",
        ["attack"] = "",
      }
    end


    -- Run the menu.
    self.result = 2
    self.cursor_position = 1
    self:update_cursor()
  end

  function messagebox_menu:on_finished()
    local game = sol.main.game
    if game ~= nil then
      -- Restore HUD mode.
      game:set_hud_mode(self.backup_hud_mode)
      
      -- Remove overriden command effects.
      if game.set_custom_command_effect ~= nil then
        for key, value in pairs(self.backup_actions) do
          game:set_custom_command_effect(key, value)
        end
      end
    end

    -- Calls the callback.
    self:done()
  end


  -------------
  -- Drawing --
  -------------

  -- Draw the menu.
  function messagebox_menu:on_draw(dst_surface)

    -- Get the destination surface size to center everything.
    local width, height = dst_surface:get_size()

    -- Dark surface.
    self:update_dark_surface(width, height)
    self.dark_surface:draw(dst_surface, 0, 0)

    -- Frame.
    local frame_w, frame_h = self.surface:get_size()
    self.frame_img:draw(self.surface, 0, 0)

    -- Text, vertically centered.
    for i = 1, #self.text_lines do
      local text_line = self.text_lines[i]
      local text_line_y = self.text_y + (i - 1) * self.menu_font_size * 2
      text_line:draw(self.surface, frame_w / 2, text_line_y + self.font_y_shift)
    end

    -- Buttons.
    for i = 1, self.button_count do
      local button_x = self.buttons[i].x
      local button_text = self.buttons[i].text
      self.button_img:draw(self.surface, button_x, self.button_y)
      button_text:draw(self.surface, button_x + 32, self.button_y + 8 + self.font_y_shift)
    end

    -- Cursor (if the position is valid).
    if self.cursor_position > 0 then
      -- Draw the cursor sprite.
      self.cursor_sprite:draw(self.surface, self.cursor_x, self.cursor_y)
    end

    -- dst_surface may be larger: draw this menu at the center.
    self.surface:draw(dst_surface, (width - frame_w) / 2, (height - frame_h) / 2)
  end

  -- Update the dark surface if necessary.
  function messagebox_menu:update_dark_surface(width, height)

    -- Check if the surface needs to be updated
    if self.dark_surface ~= nil then
      local dark_surface_w, dark_surface_h = self.dark_surface:get_size()
      if width ~= dark_surface_w or height ~= dark_surface_h then
        self.dark_surface = nil
      end
    end

    -- (Re)create the surface if necessary.
    if self.dark_surface == nil then
      self.dark_surface = sol.surface.create(width, height)
      self.dark_surface:fill_color({112, 112, 112})
      self.dark_surface:set_blend_mode("multiply")
    end
  end


  ------------
  -- Cursor --
  ------------

  -- Update the cursor.
  function messagebox_menu:update_cursor()

    -- Update coordinates.
    if self.cursor_position > 0 and self.cursor_position <= self.button_count then
      self.cursor_x = self.buttons[self.cursor_position].x + 32
    else
      self.cursor_x = -999 -- Not visible
    end

    self.cursor_y = self.button_y + 8

    -- Restart the animation.
    self.cursor_sprite:set_frame(0)
  end

  -- Update the cursor position.
  function messagebox_menu:set_cursor_position(cursor_position)

    if cursor_position ~= self.cursor_position then
      self.cursor_position = cursor_position
      self:update_cursor()
    end
  end

  -- Notify that this cursor movement is not allowed.
  function messagebox_menu:notify_cursor_not_allowed()
    self.cursor_sprite:set_frame(0)
    sol.audio.play_sound("picked_item")    
  end


  --------------
  -- Commands --
  --------------

  -- Check if a game currently exists and is started.
  function messagebox_menu:is_game_started()
    
    if sol.main.game ~= nil then
      if sol.main.game:is_started() then
        return true
      end
    end
    return false

  end

  -- Handle player input.
  function messagebox_menu:on_command_pressed(command)

    -- Action: click on the button.
    if command == "action" then
      if self.cursor_position == 1 then
        sol.audio.play_sound("cursor")
        self:accept()
      else
        sol.audio.play_sound("cursor")
        self:reject()
      end
    -- Left/Right: move the cursor.
    elseif command == "left" or command == "right" then
      if self.cursor_position == 1 and command == "right" then
        -- Go to button 2.
        self:set_cursor_position(2)
        sol.audio.play_sound("cursor")    
      elseif self.cursor_position == 2 and command == "left" then
        -- Go to button 1.
        self:set_cursor_position(1)
        sol.audio.play_sound("cursor")    
      else
        -- Blocked.
        self:notify_cursor_not_allowed()
      end
    -- Up/down: blocked.
    elseif command == "up" or command == "down" then
      self:notify_cursor_not_allowed()
    end

    -- Don't propagate the event to anything below the dialog box.
    return true
  end

  -- Hander player input when there is no lauched game yet.
  function messagebox_menu:on_key_pressed(key)

    if not self:is_game_started() then
      -- Escape: cancel the dialog (same as choosing No).
      if key == "escape" then
        self:reject()
      -- Left/right: moves the cursor.
      elseif key == "left" or key == "right" then
        if self.cursor_position == 1 and key == "right" then
          -- Go to button 2.
          self:set_cursor_position(2)
          sol.audio.play_sound("cursor")    
        elseif self.cursor_position == 2 and key == "left" then
          -- Go to button 1.
          self:set_cursor_position(1)
          sol.audio.play_sound("cursor")    
        else
          -- Blocked.
          self:notify_cursor_not_allowed()
        end
      -- Up/down: blocked.
      elseif key == "up" or key == "down" then
        self:notify_cursor_not_allowed()
      -- Space/Return: validate the button at the cursor.
      elseif key == "space" or key == "return" then
        if self.cursor_position == 1 then
          self:accept()
        else
          self:reject()
        end
      end
    end

    -- Try to bind this key on a command.
    local command = self.command_bindings[key]
    if command ~= nil then
      self:on_command_pressed(command)
    end
    
    -- Don't propagate the event to anything below the dialog box.
    return true
  end

  ------------------------
  -- Messagebox related --
  ------------------------

  -- Show the messagebox with the text in parameter.
  function messagebox_menu:show(context, text_lines, button_1_text, button_2_text, default_button_index, callback)

    -- Show the menu.
    sol.menu.start(context, self, true)
    
    -- Text.
    local line_1 = text_lines[1] or ""
    local line_2 = text_lines[2] or ""
    local line_3 = text_lines[3] or ""

    self.text_lines[1]:set_text(line_1)
    self.text_lines[2]:set_text(line_2)
    self.text_lines[3]:set_text(line_3)

    -- Buttons.
    local button_1_text = button_1_text or sol.language.get_string("messagebox.yes")
    local button_2_text = button_2_text or sol.language.get_string("messagebox.no")

    self.buttons[1].text:set_text(button_1_text)
    self.buttons[2].text:set_text(button_2_text)

    -- Callback to call when the messagebox is closed.
    self.callback = callback

    -- Default cursor position.
    if default_button_index > 0 and default_button_index <= self.button_count then
      self:set_cursor_position(default_button_index)
    else
      self:set_cursor_position(1)    
    end

  end

  -- Accept the messagebox (i.e. validate or choose Yes).
  function messagebox_menu:accept()
    self.result = 1
    sol.menu.stop(self)
  end

  -- Rejects the messagebox (i.e. cancel or choose No).
  function messagebox_menu:reject()
    self.result = 2
    sol.menu.stop(self)
  end

  -- Calls the callback when the messagebox is done.
  function messagebox_menu:done()
    if self.callback ~= nil then
      self.callback(self.result)
    end
  end

  ------------------------

  messagebox_menu:show(context, text_lines, button_1_text, button_2_text, default_button_index, callback)
end

return messagebox_builder
