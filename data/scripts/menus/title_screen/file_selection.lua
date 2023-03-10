-- File selection screen.
-- Author: Olivier Cléro (oclero@hotmail.com)

local file_selection_menu = {}

local language_manager = require("scripts/language_manager")
local game_manager = require("scripts/game_manager")
local messagebox = require("scripts/menus/messagebox")
local keyboardbox = require("scripts/menus/keyboardbox")
local settings = require("scripts/menus/settings")
local audio_manager = require("scripts/audio_manager")


----------------
-- Initialize --
----------------

function file_selection_menu:on_started()

  -- Fix the font shift (issue with some fonts)
  self.font_y_shift = 0

  -- Create static surfaces.
  self.surface = sol.surface.create(320, 240)
  self.slot_img = sol.surface.create("menus/file_selection/file_selection_slot.png")
  self.button_img = sol.surface.create("menus/file_selection/file_selection_button.png")

  -- Frame surface.
  self.frame_surface = sol.surface.create(320, 240)
  local frame_img = sol.surface.create("menus/file_selection/file_selection_frame.png")
  frame_img:draw(self.frame_surface, 8, 18)
  local title_img = sol.surface.create("menus/file_selection/file_selection_title.png")
  local title_img_w, title_img_h = title_img:get_size()
  title_img:draw(self.frame_surface, (320 - title_img_w) / 2, 8)

  -- Create sprites.
  self.cursor_sprite = sol.sprite.create("menus/file_selection/file_selection_cursor")

  -- Get fonts.
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
  self.option_1_text = sol.text_surface.create{
    color = self.text_color,
    horizontal_alignment = "center",
    font = self.menu_font,
    font_size = self.menu_font_size,
  }
  self.option_2_text = sol.text_surface.create{
    color = self.text_color,
    horizontal_alignment = "center",
    font = self.menu_font,
    font_size = self.menu_font_size,
  }
  
  -- Phases.
  self.phases = {
    CHOOSE_PLAY = 0,
    CHOOSE_DELETE = 1,
    CONFIRM_DELETE = 2,
    ENTER_NAME = 3,
    EDIT_OPTIONS = 4,
  }

  self.slot_count = 3
  self.cursor_position = 1
  self.finished = false
  self.phase = -1
  self.choosen_savegame = nil
  self:set_phase(self.phases.CHOOSE_PLAY)
  
  -- Run the menu.
  self:read_savefiles()
  self:update_cursor()

  -- Show an opening transition.
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

  -- Frame.
  self.frame_surface:draw(self.surface, 0, 0)

  -- Title.
  self.title_text:draw(self.surface, 160, 24 + self.font_y_shift)

  -- Slots.
  for i = 1, self.slot_count do
    self:draw_slot(i)
  end

  -- Buttons.
  self:draw_buttons()

  -- Cursor.
  if self.phase == self.phases.CHOOSE_DELETE or self.phase == self.phases.CHOOSE_PLAY then
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
  slot.player_name_text:draw(self.surface, self.slot_x + 32, slot_center_y + self.font_y_shift)  

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
  self.button_img:draw_region(0, 0, 96, 16, self.surface, self.button_1_x, self.button_y)
  self.option_1_text:draw(self.surface, self.button_1_x + 48, self.button_y + 7 + self.font_y_shift)

  -- Button 2.
  if self.phase == self.phases.CHOOSE_PLAY then
    self.button_img:draw_region(0, 0, 96, 16, self.surface, self.button_2_x, self.button_y)
    self.option_2_text:draw(self.surface, self.button_2_x + 48, self.button_y + 8 + self.font_y_shift)   
  end
end


------------
-- Update --
------------

function file_selection_menu:set_phase(phase)
  if phase ~= self.phase then
    self.phase = phase
    self:update_phase()
  end
end

function file_selection_menu:update_phase()
  if self.phase == self.phases.CHOOSE_PLAY or self.phase == self.phases.ENTER_NAME or self.phase == self.phases.EDIT_OPTIONS then
    self.title_text:set_text(sol.language.get_string("file_selection.choose_file"))
    self.option_1_text:set_text(sol.language.get_string("file_selection.delete"))
    self.option_2_text:set_text(sol.language.get_string("file_selection.options"))
  elseif self.phase == self.phases.CHOOSE_DELETE or self.phase == self.phases.CONFIRM_DELETE then
    self.title_text:set_text(sol.language.get_string("file_selection.delete_file"))
    self.option_1_text:set_text(sol.language.get_string("file_selection.cancel"))
    self.option_2_text:set_text("")
  else
    self.title_text:set_text("")
    self.option_1_text:set_text("")
    self.option_2_text:set_text("")
  end
end

function file_selection_menu:set_cursor_position(position)
  if position ~= self.cursor_position then
    self.cursor_position = position
    self:update_cursor()
  end
end

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

-- Get the curor's next position, either it is valid or not.
function file_selection_menu:get_cursor_next_position(current_position, key)
  local next_cursor_position = nil

  -- The cursor is on a file slot.
  if current_position > 0 and current_position <= self.slot_count then
    if key == "up" then
      next_cursor_position = current_position - 1
    elseif key == "down" then
      next_cursor_position = current_position + 1
    end
  -- The cursor is on a option button.
  elseif current_position > self.slot_count and current_position <= self.slot_count + 2 then
    if current_position == self.slot_count + 1 and key == "right" then
      next_cursor_position = current_position + 1
    elseif current_position == self.slot_count + 2 and key == "left" then
      next_cursor_position = current_position - 1
    elseif key == "up" then
      next_cursor_position = self.slot_count 
    end
  end

  -- Ensure the cursor has a valid index.
  if next_cursor_position ~= nil and (next_cursor_position < 1 or next_cursor_position > self.slot_count + 2) then
    next_cursor_position = nil
  end

  return next_cursor_position
end

-- Get the curor's next valid position.
function file_selection_menu:get_cursor_next_valid_position(current_position, key)
  local next_candidate = current_position

  repeat 
    -- Get next position.
    next_candidate = self:get_cursor_next_position(next_candidate, key)
    if next_candidate ~= nil then
      -- Check if valid.
      if self:is_cursor_position_valid(next_candidate) then
        return next_candidate
      end
    end
  until next_candidate == nil

  return current_position
end

-- Check if the cursor's position is valid.
function file_selection_menu:is_cursor_position_valid(cursor_position)
  if cursor_position == nil then
    return false
  end

  if self.phase == self.phases.CHOOSE_PLAY then
    return true
  elseif self.phase == self.phases.CHOOSE_DELETE then
    if cursor_position > 0 and cursor_position <= self.slot_count then
      local has_savegame = self.slots[cursor_position].has_savegame
      return has_savegame
    elseif cursor_position == self.slot_count + 1 then
      return true -- Button to cancel
    else
      return false
    end
  else
    return false
  end
end

-- Move the cursor according to its current location.
function file_selection_menu:move_cursor(key)
  local handled = true
  local position_count = self.slot_count + 2
  local new_cursor_position = self:get_cursor_next_valid_position(self.cursor_position, key)

  -- Update if different.
  if new_cursor_position ~= self.cursor_position then
    self:set_cursor_position(new_cursor_position)
    audio_manager:play_sound("menus/menu_cursor")
  else 
    -- Only restart the animation.
    self.cursor_sprite:set_frame(0)
    if self.cursor_position <= self.slot_count then
      self.slots[self.cursor_position].hero_sprite:set_frame(0)
    end
    audio_manager:play_sound("misc/error")
  end

  return handled
end


--------------
-- Commands --
--------------

function file_selection_menu:on_key_pressed(key)

  --if self.game:is_dialog_enabled() then
    -- Commands will be applied to the dialog box only.
    --return false
  --end

  if self.finished then
    return true
  end

  local handled = false

  if key == "escape" then
    -- Close the menu.
    handled = true
    sol.menu.stop(self)
  elseif key == "left" or key == "right" or key == "up" or key == "down" then
    -- Move the cursor.
    handled = self:move_cursor(key)
  elseif key == "space" or key == "return" then
    -- Choose the slot at the cursor.
    if self.cursor_position >= 1 and self.cursor_position <= self.slot_count then
      if self.phase == self.phases.CHOOSE_PLAY then
        handled = true
        -- Check if slot can be deleted.
        local slot = self.slots[self.cursor_position]
        if slot ~= nil then
          if sol.game.exists(slot.file_name) then
            -- The file exists: run it after a fade-out effect.            
            self.finished = true
            audio_manager:play_sound("menus/menu_select")
            self.choosen_savegame = slot.savegame
            self.surface:fade_out(20, function()
              sol.menu.stop(self)
            end)
          else
            -- The file does not exist : it's a new game.
            self:set_phase(self.phases.ENTER_NAME)

            -- Open a keyboard to allow the player to type his/her name.
            keyboardbox:show(sol.main, sol.language.get_string("file_selection.enter_name"), "", 1, 6, function(result)
              self:set_phase(self.phases.CHOOSE_PLAY)

              -- A non-empty string means the player has typed his/her name and
              -- has accepted the dialog box.
              if string.len(result) > 0 then
                -- Block player's input.
                self.finished = true

                -- Save the player's name.
                local savegame = slot.savegame
                savegame:set_value("player_name", result)
                savegame:save()

                -- Update the files.
                self:read_savefiles()

                -- Fade-out after a delay.
                sol.timer.start(self, 500, function()
                  -- Stop music.
                  sol.audio.stop_music()

                  audio_manager:play_sound("menus/menu_select")
                  self.choosen_savegame = slot.savegame
                  self.surface:fade_out(20, function()
                    -- Automatically launch the game.
                    sol.menu.stop(self)
                  end)
                end)
              end
            end)
          end
        else
          audio_manager:play_sound("misc/error")            
        end

      elseif self.phase == self.phases.CHOOSE_DELETE then
        handled = true
        self:set_phase(self.phases.CONFIRM_DELETE)
        
        -- Open a messagebox to ask the player for confirmation.
        audio_manager:play_sound("menus/menu_select")
        messagebox:show(sol.main, 
          {sol.language.get_string("file_selection.confirm_delete")}, 
          sol.language.get_string("messagebox.yes"), sol.language.get_string("file_selection.cancel"), 2,
          function(result)
          if result == 1 then
            -- Check if slot can be deleted.
            local slot = self.slots[self.cursor_position]
            if slot ~= nil then
              -- Delete file.
              audio_manager:play_sound("menus/menu_select")
              sol.game.delete(slot.file_name)
              -- Update all the files.
              self:read_savefiles()
            else
              audio_manager:play_sound("misc/error")            
            end
            
            -- Go back to first phase.
            self:set_phase(self.phases.CHOOSE_PLAY)
          else
            audio_manager:play_sound("menus/menu_select")
            -- Go back to second phase.
            self:set_phase(self.phases.CHOOSE_DELETE)       
          end
        end)
      end
    -- Press the left button.
    elseif self.cursor_position == self.slot_count + 1 then
      if self.phase == self.phases.CHOOSE_PLAY then
        audio_manager:play_sound("menus/menu_select")
        handled = true
        self:set_phase(self.phases.CHOOSE_DELETE)
        -- Set the cursor on the first valid slot.
        local first_valid_slot = 1
        if not self:is_cursor_position_valid(first_valid_slot) then
          first_valid_slot = self:get_cursor_next_valid_position(1, "down")
        end
        self:set_cursor_position(first_valid_slot)
      elseif self.phase == self.phases.CHOOSE_DELETE then
        audio_manager:play_sound("menus/menu_select")
        handled = true
        self:set_phase(self.phases.CHOOSE_PLAY)
        -- Set the cursor on the first valid slot.
        local first_valid_slot = 1
        if not self:is_cursor_position_valid(first_valid_slot) then
          first_valid_slot = self:get_cursor_next_valid_position(1, "down")
        end
        self:set_cursor_position(first_valid_slot)
      end
    -- Press the right button.
    elseif self.cursor_position == self.slot_count + 2 then
      if self.phase == self.phases.CHOOSE_PLAY then
        audio_manager:play_sound("menus/menu_select")
        handled = true

        self:set_phase(self.phases.EDIT_OPTIONS)

        -- Opens the settings
        settings:show(sol.main, function()
          self:set_phase(self.phases.CHOOSE_PLAY)
        end)
      end
    end
  end

  return handled  
end

----------------------

-- Return the menu.
return file_selection_menu
