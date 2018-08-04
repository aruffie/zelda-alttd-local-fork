-- Game settings menu.

local settings_menu = {}

local language_manager = require("scripts/language_manager")
local game_manager = require("scripts/game_manager")

function settings_menu:on_started()

  -- Create static surfaces.
  self.frame_img = sol.surface.create("menus/settings/settings_frame.png")
  local frame_w, frame_h = self.frame_img:get_size()
  self.surface = sol.surface.create(frame_w, frame_h)
  self.slot_img = sol.surface.create("menus/settings/settings_slot.png")

  -- Create sprites.
  self.cursor_sprite = sol.sprite.create("menus/settings/settings_cursor")
  self.left_arrow_sprite = sol.sprite.create("menus/settings/settings_arrow_left")
  self.right_arrow_sprite = sol.sprite.create("menus/settings/settings_arrow_right")
  self.slider_sprite = sol.sprite.create("menus/settings/settings_slider")
  self.slider_sprite:set_paused()

  -- Get fonts.
  local menu_font, menu_font_size = language_manager:get_menu_font()
  self.menu_font = menu_font
  self.menu_font_size = menu_font_size
  self.text_color = { 115, 59, 22 }
  self.text_color_light = { 177, 146, 116 }

  -- Elements positions relative to self.surface.
  self.title_x = frame_w / 2
  self.slot_spacing = 20
  self.slots_top = 40
  self.slot_x = 159
  self.texts_x = 16

  -- Prepare texts.
  self.title_text = sol.text_surface.create{
    color = self.text_color,
    horizontal_alignment = "center",
    font = self.menu_font,
    font_size = self.menu_font_size,
    text = "Settings",
  }

  self.language_text = sol.text_surface.create{
    color = self.text_color,
    horizontal_alignment = "left",
    font = self.menu_font,
    font_size = self.menu_font_size,
    text = "Language",
  }

  self.video_mode_text = sol.text_surface.create{
    color = self.text_color,
    horizontal_alignment = "left",
    font = self.menu_font,
    font_size = self.menu_font_size,
    text = "Video mode",
  }

  self.music_volume_text = sol.text_surface.create{
    color = self.text_color,
    horizontal_alignment = "left",
    font = self.menu_font,
    font_size = self.menu_font_size,
    text = "Music volume",
  }

  self.sounds_volume_text = sol.text_surface.create{
    color = self.text_color,
    horizontal_alignment = "left",
    font = self.menu_font,
    font_size = self.menu_font_size,
    text = "Sounds volume",
  }

  self.slot_count = 4
  self.cursor_position = 1
  self.editing = false
  self.finished = false

end


-------------
-- Drawing --
-------------

-- Draw the menu.
function settings_menu:on_draw(dst_surface)
  
  -- Get the destination surface size to center everything.
  local width, height = dst_surface:get_size()
  
  -- Dark surface.
  self:update_dark_surface(width, height)
  self.dark_surface:draw(dst_surface, 0, 0)

  -- Frame.
  local frame_w, frame_h = self.surface:get_size()
  self.frame_img:draw(self.surface, 0, 0) 

  -- Title.
  self.title_text:draw(self.surface, self.title_x, 10)
 
  -- Language.
  self.language_text:draw(self.surface, self.texts_x, self.slots_top)
  self:draw_slot_background(self.surface, 1)

  -- Video mode.
  self.video_mode_text:draw(self.surface, self.texts_x, self.slots_top + self.slot_spacing)
  self:draw_slot_background(self.surface, 2)
  
  -- Music volume.
  self.music_volume_text:draw(self.surface, self.texts_x, self.slots_top + self.slot_spacing * 2)
  self:draw_slot_background(self.surface, 3)
  self:draw_slider(self.surface, 3, 8)
  
  -- Sounds volume.
  self.sounds_volume_text:draw(self.surface, self.texts_x, self.slots_top + self.slot_spacing * 3)
  self:draw_slot_background(self.surface, 4)
  self:draw_slider(self.surface, 4, 5)
  
  -- Cursor (if the position is valid).
  if self.cursor_position > 0 then
    -- Draw the cursor sprite.
    self.cursor_sprite:draw(self.surface, self.cursor_x, self.cursor_y)
  end
  
  -- dst_surface may be larger: draw this menu at the center.
  self.surface:draw(dst_surface, (width - frame_w) / 2, (height - frame_h) / 2)

end

-- Update the dark surface if necessary.
function settings_menu:update_dark_surface(width, height)

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

function settings_menu:draw_slot_background(dst_surface, slot_index)

  local region_y = 0
  if slot_index == self.cursor_position and self.editing then
    region_y = 16
  end

  self.slot_img:draw_region(0, region_y, 88, 16, self.surface, self.slot_x, self.slots_top - 8 + self.slot_spacing * (slot_index - 1))

end

function settings_menu:draw_slider(dst_surface, slot_index, value)

  local x = self.slot_x + 4
  local y = self.slots_top - 5 + self.slot_spacing * (slot_index - 1)

  self.slider_sprite:set_frame(value)
  self.slider_sprite:draw(dst_surface, x, y)

end

------------
-- Cursor --
------------


--------------
-- Commands --
--------------

-- Check if a game currently exists and is started.
function settings_menu:is_game_started()
  
  if sol.main.game ~= nil then
    if sol.main.game:is_started() then
      return true
    end
  end
  return false

end


------------------------
-- Menu related --
------------------------

-- Show the menu.
function settings_menu:show(context)

  -- Show the menu.
  sol.menu.start(context, self, true)
  
end

------------------------

-- Return the menu.
return settings_menu
