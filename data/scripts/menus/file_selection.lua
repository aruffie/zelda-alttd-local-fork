-- File selection screen.

local file_selection_menu = {}

local language_manager = require("scripts/language_manager")
local game_manager = require("scripts/game_manager")
local messagebox = require("scripts/menus/messagebox")

function file_selection_menu:on_started()

  -- Create static surfaces.
  -- TODO animate background (use a sprite).  
  self.surface = sol.surface.create(320, 240)
  self.background_img = sol.surface.create("menus/file_selection/file_selection_background.png")
  self.slot_img = sol.surface.create("menus/file_selection/file_selection_slot.png")
  self.button_img = sol.surface.create("menus/file_selection/file_selection_button.png")

  -- Frame surface.
  self.frame_surface = sol.surface.create(320, 240)
  local frame_img = sol.surface.create("menus/file_selection/file_selection_frame.png")
  frame_img:draw(self.frame_surface, 8, 18)
  local title_img = sol.surface.create("menus/file_selection/file_selection_title.png")
  title_img:draw(self.frame_surface, 84, 8)

  -- Create sprites.
  self.cursor_sprite = sol.sprite.create("menus/file_selection/file_selection_cursor")

  -- Get fonts.
  --local dialog_font, dialog_font_size = language_manager:get_dialog_font()
  local menu_font, menu_font_size = language_manager:get_menu_font()
  self.menu_font = menu_font
  self.menu_font_size = menu_font_size
  self.text_color = { 115, 59, 22 }
  self.text_color_light = { 177, 146, 116 }

  -- Elements positions relative to self.surface.
  self.slot_spacing = 8
  self.slots_top = 52
  self.slot_x = 48
  self.button_1_x = 56
  self.button_2_x = 168
  self.button_y = 156
  self.cursor_x = 0
  self.cursor_y = 0

  -- Prepare texts.
  self.title_text = sol.text_surface.create{
    color = self.text_color,
    horizontal_alignment = "center",
    font = self.menu_font,
    font_size = self.menu_font_size,
  }
  self.option_erase_text = sol.text_surface.create{
    color = self.text_color,
    font = self.menu_font,
    font_size = self.menu_font_size,
  }
  self.option_settings_text = sol.text_surface.create{
    color = self.text_color,
    font = self.menu_font,
    font_size = self.menu_font_size,
  }
  
  -- Phases.
  self.phases = {
    CHOOSE_PLAY = 0,
    CHOOSE_DELETE = 1,
    CONFIRM_DELETE = 2
  }

  self.slot_count = 3
  self.cursor_position = 2
  self.finished = false
  self.phase = self.phases.CHOOSE_PLAY

  self.title_text:set_text("Choose a file")
  
  -- Run the menu.
  self:read_savefiles()
  self:update_cursor()
  sol.audio.play_music("scripts/menus/player_select")
  --self:init_phase_select_file()

  -- Commands.
  --self.game:set_custom_command_effect("action", nil)
  --self.game:set_custom_command_effect("attack", "save")

  -- Show an opening transition.
  self.background_img:fade_in()
  self.surface:fade_in()

end

-- Read the saved files.
function file_selection_menu:read_savefiles()

  self.slots = {}
  
  for i = 1, self.slot_count do
    -- Create slot.
    local slot = {}
    slot.file_name = "save" .. i .. ".dat"
    slot.savegame = game_manager:create(slot.file_name)
    slot.player_name_text = sol.text_surface.create{
      font = self.menu_font,
      font_size = self.menu_font_size,
    }
    slot.hero_sprite = sol.sprite.create("menus/file_selection/file_selection_hero")

    -- Check if the file exists.
    if sol.game.exists(slot.file_name) then
      -- Existing file.
      slot.has_savegame = true
      local name = slot.savegame:get_value("player_name")
      slot.player_name_text:set_text(name)
      slot.player_name_text:set_color(self.text_color)
      slot.hero_sprite:set_animation("still")

      -- Hearts.
      local hearts_class = require("scripts/hud/hearts")
      slot.hearts_view = hearts_class:new(slot.savegame)
    else
      -- Empty slot.
      slot.has_savegame = false
      local name = sol.language.get_string("selection_menu.empty")
      slot.player_name_text:set_text(name)
      slot.player_name_text:set_color(self.text_color_light)
      slot.hero_sprite:set_animation("empty")

      -- Hearts.
      slot.hearts_view = nil
    end

    -- Store the slot.
    self.slots[i] = slot
  end
end


----------
-- Draw --
----------

-- Draw the menu.
function file_selection_menu:on_draw(dst_surface)

  -- Get the destination surface size to center everything.
  local width, height = dst_surface:get_size()
  
  -- Background.
  self.background_img:draw(self.surface, 0, 0)

  -- Frame.
  self.frame_surface:draw(self.surface, 0, 0)

  -- Title.
  self.title_text:draw(self.surface, 160, 24)

  -- Slots.
  for i = 1, self.slot_count do
    self:draw_slot(i)
  end

  -- Buttons.
  self:draw_buttons()

  -- Cursor.
  if self.phase ~= self.phases.CONFIRM_DELETE then
    self:draw_cursor()
  end

  -- The menu is 320*240 pixels, but dst_surface may be larger.
  self.surface:draw(dst_surface, width / 2 - 160, height / 2 - 120)
end

-- Draw a slot.
function file_selection_menu:draw_slot(index)

  local slot = self.slots[index]
  local slot_y = self.slots_top + (index - 1) * (self.slot_spacing + 24)
  local slot_center_y = slot_y + 12

  -- Slot background.
  local slot_img_x = 224
  if slot.has_savegame then
    slot_img_x = 0    
  end
  
  local slot_img_y = 24
  if index == self.cursor_position then
    if self.phase == self.phases.CHOOSE_DELETE then
      slot_img_y = 48
    elseif self.phase == self.phases.CHOOSE_PLAY then
        slot_img_y = 0
    end
  end
  self.slot_img:draw_region(slot_img_x, slot_img_y, 224, 24, self.surface, self.slot_x, slot_y)
  
  -- Slot hero sprite.
  slot.hero_sprite:draw(self.surface, self.slot_x + 16, slot_center_y)

  -- Slot player's name.
  slot.player_name_text:draw(self.surface, self.slot_x + 32, slot_center_y)  

  if slot.hearts_view ~= nil then
    slot.hearts_view:set_dst_position(self.slot_x + 135, slot_y + 4)
    slot.hearts_view:on_draw(self.surface)
  end
end

-- Draw the cursor.
function file_selection_menu:draw_cursor()

  -- Check if the position is valid.
  if self.cursor_position > 0 then
    -- Draw the cursor sprite.
    self.cursor_sprite:draw(self.surface, self.cursor_x, self.cursor_y)
  end
end

-- Draw the option buttons.
function file_selection_menu:draw_buttons()

  -- Button 1.
  self.button_img:draw_region(0, 0, 96, 16, self.frame_surface, self.button_1_x, self.button_y)
  
  -- Button 2.
  if self.phase == self.phases.CHOOSE_PLAY then
    self.button_img:draw_region(0, 0, 96, 16, self.frame_surface, self.button_2_x, self.button_y)
  end
end


------------
-- Update --
------------

-- Update the cursor.
function file_selection_menu:update_cursor()

  -- Check if the position is valid.
  if self.cursor_position > 0 then
    -- Update the cursor position and animation.
    if self.cursor_position <= self.slot_count then
      -- The cursor is on a slot.
      self.cursor_sprite:set_animation("big")

      self.cursor_x = self.slot_x - 4
      self.cursor_y = self.slots_top + (self.cursor_position - 1) * (self.slot_spacing + 24) - 4
    else
      -- The cursor is on a button.
      self.cursor_sprite:set_animation("small")
      self.cursor_y = self.button_y - 4
      
      if self.cursor_position == self.slot_count + 1 then
        self.cursor_x = self.button_1_x - 4
      else
        self.cursor_x = self.button_2_x - 4
      end
    end
    -- Restart the animation.
    self.cursor_sprite:set_frame(0)

    -- Update the slots hero sprites.
    for i = 1, self.slot_count do
      local slot = self.slots[i]
      if slot.has_savegame then
        if i == self.cursor_position then
          slot.hero_sprite:set_animation("walking")
        else
          slot.hero_sprite:set_animation("still")          
        end
      else
        slot.hero_sprite:set_animation("empty")      
      end
    end
  end
end

function file_selection_menu:update_phase()
  -- TODO
end

function file_selection_menu:set_cursor_position(cursor_position)

  if cursor_position ~= self.cursor_position then
    self.cursor_position = cursor_position
    self:update_cursor()
  end
end

function file_selection_menu:get_cursor_next_position()
  -- TODO
end

function file_selection_menu:on_key_pressed(key)
  print(key)
end

function file_selection_menu:on_command_pressed(command)
  print(command)

  local handled = false

  if self.game:is_dialog_enabled() then
    -- Commands will be applied to the dialog box only.
    return false
  end

  if command == "left" or command == "right" or command == "up" or command == "down" then
    --print(command)
  elseif command == "action" or command == "attack" then
    --print(command)
  end

  return handled  
end

-- Return the menu.
return file_selection_menu
