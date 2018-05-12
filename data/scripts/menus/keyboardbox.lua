-- Dialog showing a keyboard to ask for user input.

local keyboardbox_menu = {}

local language_manager = require("scripts/language_manager")
local game_manager = require("scripts/game_manager")

function keyboardbox_menu:on_started()

  -- Elements positions relative to self.surface.
  self.textfield_x = 60
  self.textfield_y = 30
  self.keys_y = 54
  self.keys_x = 15

  -- Create static surfaces.
  self.frame_img = sol.surface.create("menus/keyboardbox/keyboardbox_frame.png")
  self.frame_w, self.frame_h = self.frame_img:get_size()

  local keys_img = sol.surface.create("menus/keyboardbox/keyboardbox_keys.png")
  keys_img:draw(self.frame_img, self.keys_x, self.keys_y)
  local textfield_img = sol.surface.create("menus/keyboardbox/keyboardbox_textfield.png")
  textfield_img:draw(self.frame_img, self.textfield_x, self.textfield_y)
  
  self.surface = sol.surface.create(self.frame_w, self.frame_h)

  self.textfield_img = sol.surface.create("menus/keyboardbox/keyboardbox_textfield.png")

  -- Prepare all different symbols.
  local symbols_img = sol.surface.create("menus/keyboardbox/keyboardbox_symbols.png")
  self.symbols = {}
  local symbol_names = {"main", "special", "shift", "cancel", "accept", "erase", }
  for i = 1, #symbol_names do
    local symbol_surface = sol.surface.create(25, 16)
    local surface_y = (i - 1) * 16
    symbols_img:draw_region(0, surface_y, 25, 16, symbol_surface)
    local symbol_name = symbol_names[i]
    self.symbols[symbol_name] = symbol_surface
  end

  -- Prepare keyboard layouts.
  local keyboard_layout_main = {
    "-", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "erase",
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
    "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    "shift", "special", " ", "cancel", "accept",
  }

  local keyboard_layout_main_upper = {}
  for i = 1, #keyboard_layout_main do
    keyboard_layout_main_upper[i] = string.upper(keyboard_layout_main[i])
  end

  local keyboard_layout_special = {
    "à", "á", "â", "ã", "ä", "å", "æ", "è", "é", "ê", "ë", "erase",
    "ç", "đ", "ì", "í", "î", "ï", "ñ", "ò", "ó", "ô", "õ", "ö", "ø",
    "ù", "ú", "û", "ü", "ý", "œ", "ß", "&", "@", "'", "$", "€", "£", 
    "shift", "main", " ", "cancel", "accept",
  }

  local keyboard_layout_special_upper = {}
  for i = 1, #keyboard_layout_special do
    keyboard_layout_special_upper[i] = string.upper(keyboard_layout_special[i])
  end

  self.keyboard_layouts = {
    "lower" = {
      "main" = {
        map = keyboard_layout_main,
      },
      "special" = {
        map = keyboard_layout_special,
      },
    },
    "upper" = {
      "main" = {
        map = keyboard_layout_main_upper,
      },
      "special" = {
        map = keyboard_layout_special_upper,
      },
    }
  }

  local cursor_sprite_sizes = { "normal", "special", "double", "long", }
  local keyboard_layout_keys = {
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    2, 2, 4, 2, 2,
  }

  -- Compute position for each key (useful to draw letters and cursor).
  self.keyboard_layout_geometries = {}
  local key_spacing = 2
  for i = 1, #keyboard_layout_keys do
    local key_type = keyboard_layout_keys[i]
    local key_cursor_type = cursor_sprite_sizes[key_type]

    local key_x = 0
    local key_y = 0
    if i <= 12 then
      key_x = self.keys_x + (i - 1) * (16 + key_spacing)
      key_y = self.keys_y
    elseif i >= 13 and i <= 25 then
      key_x = self.keys_x + (i - 1 - 12) * (16 + key_spacing)
      key_y = self.keys_y + 16 + key_spacing
    elseif i >= 26 and i <= 38 then
      key_x = self.keys_x + (i - 1 - 25) * (16 + key_spacing)
      key_y = self.keys_y + 2 * (16 + key_spacing)
    elseif i == 39 then
      key_x = 33
      key_y = 108
    elseif i == 40 then
      key_x = 60
      key_y = 108
    elseif i == 41 then
      key_x = 87
      key_y = 108
    elseif i == 42 then
      key_x = 177
      key_y = 108
    elseif i == 43 then
      key_x = 204
      key_y = 108
    end
    
    self.keyboard_layout_geometries[i] = {
      x = key_x,
      y = key_y,
      cursor_size = key_cursor_type,
    }
  end
  
  -- Get fonts.
  local menu_font, menu_font_size = language_manager:get_menu_font()
  self.menu_font = menu_font
  self.menu_font_size = menu_font_size
  self.text_color = { 115, 59, 22 }
  self.text_color_light = { 177, 146, 116 }

  -- Prepare keyboard layouts surfaces.
  for _, value_1 in pairs(self.keyboard_layouts) do
    for _, value_2 in pairs(value_1) do
      value_2.surface = sol.surface.create(self.frame_w, self.frame_h)

      -- TODO dessiner la surface (cf ci-dessous)
    end
  end

  ----------------------------
  self.keyboard_layout_main_surface = sol.surface.create(self.frame_w, self.frame_h)

  for i = 1, #self.keyboard_layout_geometries do
    local layout_item_content = self.keyboard_layout_main[i]
    local layout_item_geometry = self.keyboard_layout_geometries[i]

    -- Check if the key is a letter or a special key.
    local symbol_surface = self.symbols[string.lower(layout_item_content)]
    -- It's a letter.
    if symbol_surface == nil then
      local letter_text = sol.text_surface.create{
        color = self.text_color,
        horizontal_alignment = "center",
        font = self.menu_font,
        font_size = self.menu_font_size,
        text = layout_item_content
      }

      local letter_x = layout_item_geometry.x + 8
      local letter_y = layout_item_geometry.y + 8

      letter_text:draw(self.keyboard_layout_main_surface, letter_x, letter_y)

    -- It's a special key.
    else
      
      local symbol_x = layout_item_geometry.x
      local symbol_y = layout_item_geometry.y

      -- Special case for the erase key.
      if string.lower(layout_item_content) == "erase" then
        symbol_x = symbol_x + 4 
      end

      symbol_surface:draw(self.keyboard_layout_main_surface, symbol_x, symbol_y)

    end
  end

  --------------------------------

  -- Prepare texts.
  self.title_text = sol.text_surface.create{
    color = self.text_color,
    horizontal_alignment = "center",
    font = self.menu_font,
    font_size = self.menu_font_size,
  }

  self.textfield_text = sol.text_surface.create{
    color = self.text_color,
    horizontal_alignment = "center",
    font = self.menu_font,
    font_size = self.menu_font_size,
  }

  -- Create sprites.
  self.cursor_sprite = sol.sprite.create("menus/keyboardbox/keyboardbox_cursor")
  self.textfield_cursor_sprite = sol.sprite.create("menus/keyboardbox/keyboardbox_textfield_cursor")

  -- Callback when the menu is done.
  self.callback = function(result)
  end
  
  -- Custom commands effects
  local game = sol.main.game
  if game ~= nil then
    if game.set_custom_command_effect ~= nil then
        game:set_custom_command_effect("action", "return")
        game:set_custom_command_effect("attack", nil)
    end
  end
  
  -- Dummy text to test.
  self.title_text:set_text("What's your name?")
  self:set_result("Link")

  -- Run the menu.
  self.max_result_size = 6
  self.cursor_position = 41
  self:update_cursor()

end

-- Draw the menu.
function keyboardbox_menu:on_draw(dst_surface)

  -- Get the destination surface size to center everything.
  local width, height = dst_surface:get_size()
  
  -- Dark surface.
  self:update_dark_surface(width, height)
  self.dark_surface:draw(dst_surface, 0, 0)

  -- Frame.
  self.frame_img:draw(self.surface, 0, 0)

  -- Title.
  local frame_center_x = self.frame_w / 2
  self.title_text:draw(self.surface, frame_center_x, 16)

  -- Text field.
  self.textfield_text:draw(self.surface, frame_center_x, 38)
  local textfield_text_w, textfield_text_h = self.textfield_text:get_size()
  self.textfield_cursor_sprite:draw(self.surface, frame_center_x + textfield_text_w / 2, 38)

  -- Current keyboard layout.
  self.keyboard_layout_main_surface:draw(self.surface, 0, 0)

  -- Cursor.
  self:draw_cursor(self.surface)

  -- dst_surface may be larger: draw this menu at the center.
  self.surface:draw(dst_surface, (width - self.frame_w) / 2, (height - self.frame_h) / 2)
end

-- Update the dark surface if necessary.
function keyboardbox_menu:update_dark_surface(width, height)

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

-- Draw the cursor.
function keyboardbox_menu:draw_cursor(dst_surface)

  -- Check if the position is valid.
  if self.cursor_position > 0 then
    -- Draw the cursor sprite.
    self.cursor_sprite:draw(dst_surface, self.cursor_x, self.cursor_y)
  end
end

-- Change the cursor position.
function keyboardbox_menu:set_cursor_position(position)
  if position ~= self.cursor_position then
    self.cursor_position = position
    self:update_cursor()
  end
end

-- Update the cursor (change x, y and sprite according to position).
function keyboardbox_menu:update_cursor()

  if self.cursor_position > 0 then
    local item_geometry = self.keyboard_layout_geometries[self.cursor_position]
    
    -- Update coordinates.
    self.cursor_x = item_geometry.x - 4
    self.cursor_y = item_geometry.y - 4
    
    -- Update the animation.
    self.cursor_sprite:set_animation(item_geometry.cursor_size)
  else
    -- Update coordinates to make the cursor not visible.
    self.cursor_x = -999
    self.cursor_y = -999

    -- Update the animation.    
    self.cursor_sprite:set_animation("none")
  end

  -- Restart the animation.
  self.cursor_sprite:set_frame(0)
end

-- Move the cursor according to its current location.
function keyboardbox_menu:move_cursor(key)
  local handled = true
  local new_cursor_position = self:get_cursor_next_position(self.cursor_position, key)

  self:set_cursor_position(new_cursor_position)
  sol.audio.play_sound("cursor")

  return handled
end

-- Get the curor's next valid position.
function keyboardbox_menu:get_cursor_next_position(current_position, key)
  local next_position = current_position

  if current_position == 1 then

  elseif current_position > 1 and current_position < 12 then
  
  elseif current_position == 12 then

  elseif current_position >= 13 and current_position <= 25 then

  elseif current_position >= 26 and current_position <= 38 then

  elseif current_position >= 39 and current_position <= 43 then
    
  else
    next_position = 1
  end

  return next_position
end

-- Change the displayed text in the textfield.
function keyboardbox_menu:set_result(result)
  local truncated_result = string.sub(result, 1, 6)
  print(truncated_result)
  self.result = truncated_result
  self.textfield_text:set_text(truncated_result)
end

-- Press the key.
function keyboardbox_menu:validate_cursor()
  -- Check if the key is a letter or a special key.
  local layout_item_content = self.keyboard_layout_main[self.cursor_position]
  local symbol_surface = self.symbols[layout_item_content]
  
  if symbol_surface == nil then
    self:add_letter(layout_item_content)
  else
    local special_key = string.lower(layout_item_content)
    if special_key == "erase" then
      self:erase()
    elseif special_key == "shift" then
      self:shift()
    elseif special_key == "main" or special_key == "special" then
      self:set_layout(layout_item_content)    
    elseif special_key == "cancel" then
      self:reject()
    elseif special_key == "accept" then
      self:accept()  
    else
      sol.audio.play_sound("wrong")
    end
  end
end

function keyboardbox_menu:add_letter(letter)
  if string.len(self.result) < self.max_result_size then
    self:set_result(self.result..letter)
    sol.audio.play_sound("ok")
  else
    sol.audio.play_sound("wrong")
  end
end

function keyboardbox_menu:erase()
  if string.len(self.result) > 0 then
    self:set_result(string.sub(self.result, 1, string.len(self.result) - 1))
    sol.audio.play_sound("ok")
  else
    sol.audio.play_sound("wrong")
  end
end

function keyboardbox_menu:shift()

end

function keyboardbox_menu:set_layout(layout)

end

-- Hander player input when there is no lauched game yet.
function keyboardbox_menu:on_key_pressed(key)

  if not self:is_game_started() then
    -- Escape: cancel the dialog (same as choosing No).
    if key == "escape" then
      self:reject()
    -- Left/right/up/down: moves the cursor.
    elseif key == "left" or key == "right" or key == "up" or key == "down" then
      self:move_cursor(key)
    elseif key == "backspace" then
      self:erase()      
    -- Space/Return: validate the button at the cursor.
    elseif key == "space" or key == "return" then
      self:validate_cursor()
    end
  end

  -- Don't propagate the event to anything below the dialog box.
  return true
end

-- Accept the keyboardbox.
function keyboardbox_menu:accept()
  self:done()
  sol.menu.stop(self)
end

-- Rejects the keyboardbox.
function keyboardbox_menu:reject()
  self.result = ""
  self:done()
  sol.menu.stop(self)
end

-- Calls the callback when the keyboardbox is done.
function keyboardbox_menu:done()
  if self.callback ~= nil then
    self.callback(self.result)
  end
end

-- Check if a game currently exists and is started.
function keyboardbox_menu:is_game_started()
  
  if sol.main.game ~= nil then
    if sol.main.game:is_started() then
      return true
    end
  end
  return false

end

------------------------

-- Return the menu.
return keyboardbox_menu
