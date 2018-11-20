-- Game settings menu.

local settings_menu = {}

local language_manager = require("scripts/language_manager")
local game_manager = require("scripts/game_manager")
local audio_manager = require("scripts/audio_manager")

function settings_menu:on_started()

  -- Fix the font shift (issue with Minecraftia)
  self.font_y_shift = 0

  -- Create static surfaces.
  self.frame_img = sol.surface.create("menus/settings/settings_frame.png")
  local frame_w, frame_h = self.frame_img:get_size()
  self.surface = sol.surface.create(frame_w, frame_h)
  self.slot_img = sol.surface.create("menus/settings/settings_slot.png")
  self.back_img = sol.surface.create("menus/settings/settings_button_back.png")

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
  self.slot_y = 40
  self.slot_x = 156
  self.text_x = 16

  -- Title.
  self.title_text = sol.text_surface.create{
    color = self.text_color,
    horizontal_alignment = "center",
    font = self.menu_font,
    font_size = self.menu_font_size,
    text_key = "settings.title",
  }
  
  -- Options.
  self.options = {
    {
      name = "language",
      type = "text",
      values = sol.language.get_languages(),
    },
    {
      name = "video_filter",
      type = "text",
      values = sol.video.get_modes(),
    },
    {
      name = "music_volume",
      type = "integer",
      values = { 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 },
    },
    {
      name = "sound_volume",
      type = "integer",
      values = { 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 },
    }
  }

  for _, option in ipairs(self.options) do
    local value_text = sol.text_surface.create()
    
    option.label_text = sol.text_surface.create{
      font = self.menu_font,
      font_size = self.menu_font_size,
      text_key = "settings." .. option.name,
      color = self.text_color,
      horizontal_alignment = "left",
    }

    option.value_text = sol.text_surface.create{
      font = self.menu_font,
      font_size = self.menu_font_size,
      color = self.text_color,
      horizontal_alignment = "center",
    }

    self:load_option(option)

  end
 
  -- Back button.
  self.back_text = sol.text_surface.create{
    color = self.text_color,
    horizontal_alignment = "center",
    font = self.menu_font,
    font_size = self.menu_font_size,
    text_key = "settings.back",
  }
  
  self.slot_count = 4
  self.cursor_position = 1
  self.editing = false
  self.finished = false
  self:update_cursor()
  
  self.surface:fade_in(10)

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

  self.surface:clear()

  -- Frame.
  local frame_w, frame_h = self.surface:get_size()
  self.frame_img:draw(self.surface, 0, 0) 

  -- Title.
  self.title_text:draw(self.surface, self.title_x, 10 + self.font_y_shift)
 
  for i, option in ipairs(self.options) do   
    -- Background
    self:draw_slot_background(self.surface, i)

    -- Label
    option.label_text:draw(self.surface, self.text_x, self.slot_y + self.slot_spacing * (i - 1) + self.font_y_shift)

    -- Value
    if option.type == "text" then
      option.value_text:draw(self.surface, self.slot_x + 44, self.slot_y + self.slot_spacing * (i - 1) + self.font_y_shift)
    elseif option.type == "integer" then
      self:draw_slider(self.surface, i)
      self:draw_slider_value(self.surface, i)
    end
  end
  
  -- Back button.
  self.back_img:draw(self.surface, self.slot_x, self.slot_y + self.slot_spacing * 4)
  self.back_text:draw(self.surface, self.slot_x + 44, self.slot_y + self.slot_spacing * 4 + 8 + self.font_y_shift)

  -- Cursor (if the position is valid).
  if self.cursor_position > 0 and self.cursor_position <= self.slot_count + 1 then
    if self.editing then
      -- Draw the arrows.
      self.left_arrow_sprite:draw(self.surface, self.cursor_x - 12, self.cursor_y + 2)
      self.right_arrow_sprite:draw(self.surface, self.cursor_x + 84, self.cursor_y + 2)

    else
      -- Draw the cursor sprite.
      self.cursor_sprite:draw(self.surface, self.cursor_x, self.cursor_y)
    end
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

-- Draws a slot.
function settings_menu:draw_slot_background(dst_surface, slot_index)

  local region_y = 0
  if slot_index == self.cursor_position and self.editing then
    region_y = 16
  end

  self.slot_img:draw_region(0, region_y, 88, 16, self.surface, self.slot_x, self.slot_y - 8 + self.slot_spacing * (slot_index - 1))

end

-- Draws a slider.
function settings_menu:draw_slider(dst_surface, slot_index)

  local x = self.slot_x + 8
  local y = self.slot_y - 5 + self.slot_spacing * (slot_index - 1)
  local option = self.options[slot_index]

  local frame_index = math.max(0, math.min(10, math.floor(option.value / 10)))

  self.slider_sprite:set_frame(frame_index)
  self.slider_sprite:draw(dst_surface, x, y)

end

-- Draws the text of the slider's value.
function settings_menu:draw_slider_value(dst_surface, slot_index)

  local x = self.slot_x + 64 + 8
  local y = self.slot_y + self.slot_spacing * (slot_index - 1)

  self.options[slot_index].value_text:draw(dst_surface, x, y + self.font_y_shift)

end


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

-- Hander player input when there is no lauched game yet.
function settings_menu:on_key_pressed(key)

  if not self:is_game_started() and not self.finished then
      -- Escape: cancel the dialog (same as choosing No).
      if key == "escape" then
        self:close()

      elseif key == "up" or key == "down" or key == "left" or key == "right" then

        -- Left/right: moves the cursor when editing an option.
        if self.editing == true and self.cursor_position <= self.slot_count then
          if key == "left" or key == "right" then 
            
            local option = self.options[self.cursor_position]
            local next_value = self:get_option_next_value(option, key)
            if next_value ~= option.value then
              audio_manager:play_sound("menus/menu_cursor")
              self:set_option(option, next_value)
              self:load_option(option)
            else
              self:notify_cursor_not_allowed()        
            end

            self.left_arrow_sprite:set_frame(0)
            self.right_arrow_sprite:set_frame(0)

          else
            self:notify_cursor_not_allowed()        
          end

        -- Up/down: moves the cursor when choosing which option to edit.
        elseif self.editing == false then
          if key == "up" or key == "down" then
            local new_cursor_position = self:get_cursor_next_position(self.cursor_position, key)
            local new_position_is_valid = new_cursor_position > 0 and new_cursor_position <= self.slot_count + 1

            -- Update if different.
            if new_cursor_position ~= self.cursor_position and new_position_is_valid then
              self:set_cursor_position(new_cursor_position)
              audio_manager:play_sound("menus/menu_cursor")
            else 
              -- Only restart the animation.
              self.cursor_sprite:set_frame(0)
              audio_manager:play_sound("picked_item")
            end
          else
            self:notify_cursor_not_allowed()
          end
        end

      -- Space/Return: validate the option at the cursor.
      elseif key == "space" or key == "return" then
        if self.cursor_position > 0 and self.cursor_position <= self.slot_count then
          self.editing = not self.editing
        elseif self.cursor_position == self.slot_count + 1 then
          self:close()
        end
      end
  end

  -- Don't propagate the event to anything below the dialog box.
  return true

end


------------
-- Cursor --
------------

-- Notify that this cursor movement is not allowed.
function settings_menu:notify_cursor_not_allowed()
  self.cursor_sprite:set_frame(0)
  audio_manager:play_sound("picked_item")    
end

-- Get the curor's next position, either it is valid or not.
function settings_menu:get_cursor_next_position(current_position, key)
  local next_cursor_position = -1

  if current_position > 0 and current_position <= self.slot_count + 1 then
    if key == "up" then
      next_cursor_position = current_position - 1
    elseif key == "down" then
      next_cursor_position = current_position + 1
    end
  end

  -- Ensure the cursor has a valid index.
  if next_cursor_position < 1 or next_cursor_position > self.slot_count + 1 then
    next_cursor_position = -1
  end

  return next_cursor_position
end

function settings_menu:set_cursor_position(position)
  if position ~= self.cursor_position then
    self.cursor_position = position
    self:update_cursor()
  end
end

-- Update the cursor.
function settings_menu:update_cursor()

  -- Check if the position is valid.
  if self.cursor_position > 0 then
    -- Update the cursor position and animation.
    if self.cursor_position <= self.slot_count then
      self.cursor_x = self.slot_x
      self.cursor_y = self.slot_y + (self.cursor_position - 1) * self.slot_spacing - 8
    else
      -- The cursor is on Back button.
      self.cursor_x = self.slot_x
      self.cursor_y = self.slot_y + (self.cursor_position - 1) * self.slot_spacing
    end

    -- Restart the animation.
    self.cursor_sprite:set_frame(0)
  end
end

-- Valeur suivante dans la liste de valeurs de l'option.
function settings_menu:get_option_next_value(option, key)

  local values = option.values
  local values_count = #values;

  local current_index = 0
  for i, value in ipairs(values) do
    if value == option.value then
      current_index = i
    end
  end

  local next_index = current_index
  if key == "left" then
    next_index = current_index - 1
  elseif key == "right" then
    next_index = current_index + 1
  end

  if option.type ~= "integer" then
    next_index = (next_index - 1) % values_count + 1
  else
    next_index = math.max(1, math.min(values_count, next_index))
  end

  return values[next_index]

end


------------------------
-- Menu related --
------------------------

-- Show the menu.
function settings_menu:show(context, callback)
  
  -- Show the menu.
  sol.menu.start(context, self, true)
  
  callback = callback or nil
  self.callback = callback
  
end

-- Quits this menu.
function settings_menu:close(callback)
  
  audio_manager:play_sound("menus/pause_menu_close")

  -- Block cursor
  self.finished = true
  self.editing = false
  self.left_arrow_sprite:set_paused(true)
  self.right_arrow_sprite:set_paused(true)
  self.cursor_sprite:set_paused(true)
 
  -- Fade out
  local delay = 10
  if self.dark_surface ~= nil then
    self.dark_surface:fade_out(delay)
  end

  self.surface:fade_out(delay, function()
    -- Call the callback.
    if self.callback ~= nil then
      self.callback()
    end

    sol.menu.stop(self)
  end)

end

function settings_menu:load_options()
  
  for _, option in self.options do
    self:load_option(option)
  end
end

function settings_menu:load_option(option)
  
  if option.name == "language" then
    option.value = sol.language.get_language()
    option.value_text:set_text(sol.language.get_language_name(option.value))

  elseif option.name == "video_filter" then
    option.value = sol.video.get_mode()
    option.value_text:set_text(option.value)

  elseif option.name == "music_volume" then
    option.value = math.floor((sol.audio.get_music_volume() + 5) / 10) * 10
    option.value_text:set_text(tostring(option.value))

  elseif option.name == "sound_volume" then
    option.value = math.floor((sol.audio.get_sound_volume() + 5) / 10) * 10
    option.value_text:set_text(tostring(option.value))

  end
end

function settings_menu:set_option(option, value)

  option.value = value

  if option.name == "language" then
    sol.language.set_language(value)

  elseif option.name == "video_filter" then
    sol.video.set_mode(value)

  elseif option.name == "music_volume" then
    sol.audio.set_music_volume(value)

  elseif option.name == "sound_volume" then
    sol.audio.set_sound_volume(value)

  end
end


------------------------

-- Return the menu.
return settings_menu
