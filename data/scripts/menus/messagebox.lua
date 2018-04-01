-- Simple message box dialog.

local messagebox_menu = {}

local language_manager = require("scripts/language_manager")
local game_manager = require("scripts/game_manager")

function messagebox_menu:on_started()

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
  self.button_1_x = 24
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
  
  self.button_1_text = sol.text_surface.create{
    color = self.text_color,
    font = self.menu_font,
    font_size = self.menu_font_size,
    horizontal_alignment = "center",
  }
  self.button_2_text = sol.text_surface.create{
    color = self.text_color,
    font = self.menu_font,
    font_size = self.menu_font_size,
    horizontal_alignment = "center",
  }

  self.text_lines[1]:set_text("Are you sure?")
  self.text_lines[2]:set_text("Second line")
  self.text_lines[3]:set_text("Third line")
  self.button_1_text:set_text("Yes")
  self.button_2_text:set_text("No")
  
  -- Run the menu.
  self.cursor_position = 1
  self:update_cursor()
end

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

  -- Text.
  for i = 1, #self.text_lines do
    local text_line = self.text_lines[i]
    local text_line_y = self.text_y + (i - 1) * self.menu_font_size * 1.75
    text_line:draw(self.surface, frame_w / 2, text_line_y)
  end

  -- Buttons.
  self.button_img:draw(self.surface, self.button_1_x, self.button_y)
  self.button_1_text:draw(self.surface, self.button_1_x + 32, self.button_y + 8)

  self.button_img:draw(self.surface, self.button_2_x, self.button_y)
  self.button_2_text:draw(self.surface, self.button_2_x + 32, self.button_y + 8)

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

-- Update the cursor.
function messagebox_menu:update_cursor()

  -- Check if the position is valid.
  if self.cursor_position > 0 then
    self.cursor_x = self.button_1_x + 32
    self.cursor_y = self.button_y + 8

    -- Restart the animation.
    self.cursor_sprite:set_frame(0)
  end
end

-- Update the cursor position.
function messagebox_menu:set_cursor_position(cursor_position)

  if cursor_position ~= self.cursor_position then
    self.cursor_position = cursor_position
    self:update_cursor()
  end
end

-- Return the menu.
return messagebox_menu
