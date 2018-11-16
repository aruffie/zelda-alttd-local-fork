-- Base class of each submenu.

local submenu = {}

local language_manager = require("scripts/language_manager")
local messagebox = require("scripts/menus/messagebox")
local text_fx_helper = require("scripts/text_fx_helper")

function submenu:new(game)
  
  local o = { game = game }
  setmetatable(o, self)
  self.__index = self
  return o
end

function submenu:on_started()

  -- Fix the font shift (issue with Minecraftia)
  self.font_y_shift = 0
  
  -- State.
  self.save_messagebox_opened = false
  
  -- Load images.
  self.background_surfaces = sol.surface.create("menus/pause/submenus.png")
  self.title_arrows = sol.surface.create("menus/pause/submenus_arrows.png")
  self.caption_background = sol.surface.create("menus/pause/submenus_caption.png") 
  self.caption_background_w, self.caption_background_h = self.caption_background:get_size()
  
  -- Dark surface whose goal is to slightly hide the game and better highlight the menu.
  local quest_w, quest_h = sol.video.get_quest_size()
  self.dark_surface = sol.surface.create(quest_w, quest_h)
  self.dark_surface:fill_color({112, 112, 112})
  self.dark_surface:set_blend_mode("multiply")
  
  -- Create captions.
  local menu_font, menu_font_size = language_manager:get_menu_font()
  self.text_color = { 115, 59, 22 }
  self.caption_text_1 = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    font = menu_font,
    font_size = menu_font_size,
    color = self.text_color,
  }
  self.caption_text_2 = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    font = menu_font,
    font_size = menu_font_size,
    color = self.text_color,
  }

  -- Create title.
  self.title = ""
  self.title_text = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    font = menu_font,
    font_size = menu_font_size,
    color = {255, 255, 255},
  }
  self.title_stroke_color = {158, 117, 70}
  self.title_shadow_color = {85, 20, 0}
  self.title_surface = sol.surface.create(88, 16)

  -- Command icons.
  self.game:set_custom_command_effect("action", nil)
  self.game:set_custom_command_effect("attack", "save")
  
  self.dialog_opened = false
  -- Automatically starts the pause menu when the game is set on pause.
  self.game:register_event("on_dialog_started", function(game)
    self.backup_dialog_opened = self.dialog_opened
    self.dialog_opened = true
  end)

  -- Automatically stops the pause menu when the game is unpaused.
  self.game:register_event("on_dialog_finished", function(game)
    self.dialog_opened = self.backup_dialog_opened
  end)
end

-- Sets the caption text.
-- The caption text can have one or two lines, with 20 characters maximum for each line.
-- If the text you want to display has two lines, use the '$' character to separate them.
-- A value of nil removes the previous caption if any.
function submenu:set_caption(text_key)

  if text_key == nil then
    self.caption_text_1:set_text(nil)
    self.caption_text_2:set_text(nil)
  else
    local text = sol.language.get_string(text_key)
    local line1, line2 = text:match("([^$]+)%$(.*)")
    if line1 == nil then
      -- Only one line.
      self.caption_text_1:set_text(text)
      self.caption_text_2:set_text(nil)
    else
      -- Two lines.
      self.caption_text_1:set_text(line1)
      self.caption_text_2:set_text(line2)
    end
  end
end

-- Draw the caption text previously set.
function submenu:draw_caption(dst_surface)

  -- Draw only if save dialog is not displayed.
  if not self.dialog_opened then
    local width, height = dst_surface:get_size()

    -- Draw caption frame.
    self.caption_background:draw(dst_surface, (width - self.caption_background_w) / 2, height / 2 + 74)

    -- Draw caption text.
    if self.caption_text_2:get_text():len() == 0 then
      self.caption_text_1:draw(dst_surface, width / 2, height / 2 + 92 + self.font_y_shift)
    else
      self.caption_text_1:draw(dst_surface, width / 2, height / 2 + 86 + self.font_y_shift)
      self.caption_text_2:draw(dst_surface, width / 2, height / 2 + 100 + self.font_y_shift)
    end
  end
end

-- Goes to the next pause screen.
function submenu:next_submenu()

  sol.audio.play_sound("pause_closed")
  sol.menu.stop(self)
  local submenus = self.game.pause_submenus
  local submenu_index = self.game:get_value("pause_last_submenu")
  submenu_index = (submenu_index % #submenus) + 1
  self.game:set_value("pause_last_submenu", submenu_index)
  sol.menu.start(self.game.pause_menu, submenus[submenu_index], false)
end

-- Goes to the previous pause screen.
function submenu:previous_submenu()

  sol.audio.play_sound("pause_closed")
  sol.menu.stop(self)
  local submenus = self.game.pause_submenus
  local submenu_index = self.game:get_value("pause_last_submenu")
  submenu_index = (submenu_index - 2) % #submenus + 1
  self.game:set_value("pause_last_submenu", submenu_index)
  sol.menu.start(self.game.pause_menu, submenus[submenu_index], false)
end

-- Shows the messagebox to save the game.
function submenu:show_save_messagebox()
  sol.audio.play_sound("pause_open")
  messagebox:show(self, 
    -- Text lines.
    {
     sol.language.get_string("save_dialog.save_question_0"),
     sol.language.get_string("save_dialog.save_question_1"),
    },
    -- Buttons
    sol.language.get_string("messagebox.yes"),
    sol.language.get_string("messagebox.no"),
    -- Default button
    1,
    -- Callback called after the user has chosen an answer.
    function(result)
      if result == 1 then
        self.game:save()
      end
    
      -- Ask the user if he/she wants to continue the game.
      self:show_continue_messagebox()
  end)
end

-- Show the messagebox to ask the user if he/she wants to continue.
function submenu:show_continue_messagebox()
  sol.audio.play_sound("pause_open")
  messagebox:show(self, 
    -- Text lines.
    {
     sol.language.get_string("save_dialog.continue_question_0"),
     sol.language.get_string("save_dialog.continue_question_1"),
    },
    -- Buttons
    sol.language.get_string("messagebox.yes"),
    sol.language.get_string("messagebox.no"),
    -- Default button
    1,
    -- Callback called after the user has chosen an answer.
    function(result)
      if result == 2 then
        sol.main.reset()
      end
    
  end) 
end

-- Commands to navigate in the pause menu. 
function submenu:on_command_pressed(command)

  local handled = false

  if self.game:is_dialog_enabled() then
    -- Commands will be applied to the dialog box only.
    return false
  end

  if command == "attack" and not self.dialog_opened then
    self.dialog_opened = true
    self:show_save_messagebox()
    return true
  end

  return handled
end

function submenu:draw_background(dst_surface)

  local width, height = dst_surface:get_size()

  -- Fill the screen with a dark surface.
  self.dark_surface:draw(dst_surface)

  -- Draw the menu GUI window &ns the title (in the correct language)
  local submenu_index = self.game:get_value("pause_last_submenu")
  self.background_surfaces:draw_region(
      320 * (submenu_index - 1), 0,           -- region x, y
      320, 240,                               -- region w, h
      dst_surface,                            -- destination surface
      (width - 320) / 2, (height - 240) / 2   -- pos in destination surface
  )
  self.title_surface:draw(dst_surface, (width - 88) / 2, ((height - 240) / 2 ) + 32)

  -- Draw only if save dialog is not displayed.
  if not self.dialog_opened then
    -- Draw arrows on both sides of the menu title
    local center_x = width / 2
    local center_y = height / 2
    self.title_arrows:draw_region(0, 0, 14, 12, dst_surface, center_x - 71, center_y - 88)
    self.title_arrows:draw_region(14, 0, 14, 12, dst_surface, center_x + 57, center_y - 88)
  end
end

function submenu:set_title(text)
  if text ~= self.title then
    self.title = text
    self:rebuild_title_surface()
  end
end

function submenu:rebuild_title_surface()
  self.title_surface:clear()
  local w, h = self.title_surface:get_size()
  self.title_text:set_text(self.title)
  self.title_text:set_xy(w / 2, h / 2 - 2)
  text_fx_helper:draw_text_with_stroke_and_shadow(self.title_surface, self.title_text, self.title_stroke_color, self.title_shadow_color)
end

-- Return the menu.
return submenu
