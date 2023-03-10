local submenu = require("scripts/menus/pause/pause_submenu")
local audio_manager = require("scripts/audio_manager")

local inventory_submenu = submenu:new()
local item_names_assignable = {
  "shield",
  "mushroom",
  "ocarina",
  "feather",
  "bombs_counter",
  "shovel",
  "pegasus_shoes",
  "hookshot",
  "bow",
  "fire_rod",
  "hammer"
}
local item_names_static = {
  "tunic",
  "sword",
  "flippers",
  "power_bracelet",
  "drug"
}

function inventory_submenu:on_started()

  submenu.on_started(self)
      
  -- Set title
  self:set_title(sol.language.get_string("inventory.title"))

  self.cursor_sprite = sol.sprite.create("menus/pause/cursor")
  self.sprites_assignables = {}
  self.sprites_static = {}
  self.captions = {}
  self.counters = {}
  self.menu_ocarina = false
  if self.game:has_item("magic_powder_counter") and self.game:get_item("magic_powder_counter"):get_amount() > 0 then
    item_names_assignable[2] = "magic_powder_counter"
  else
    item_names_assignable[2] = "mushroom"
  end
  if self.game:get_value("get_boomerang") then
    item_names_assignable[6] = "boomerang"
  end

  -- Initialize the cursor
  local index = self.game:get_value("pause_inventory_last_item_index") or 0
  local row = math.floor(index / 7)
  local column = index % 7
  self:set_cursor_position(row, column)
  
  -- Load Items
  for i,item_name in ipairs(item_names_assignable) do
    local item = self.game:get_item(item_name)
    local variant = item:get_variant()
    self.sprites_assignables[i] = sol.sprite.create("entities/items")
    self.sprites_assignables[i]:set_animation(item_name)
    if item:has_amount() then
      -- Show a counter in this case.
      local amount = item:get_amount()
      local maximum = item:get_max_amount()
      self.counters[i] = sol.text_surface.create{
        horizontal_alignment = "center",
        vertical_alignment = "top",
        text = item:get_amount(),
        font = (amount == maximum) and "green_digits" or "white_digits",
      }
    end
  end
  
  for i,item_name in ipairs(item_names_static) do
    local item = self.game:get_item(item_name)
    local variant = item:get_variant()
    self.sprites_static[i] = sol.sprite.create("entities/items")
    self.sprites_static[i]:set_animation(item_name)
  end
end

function inventory_submenu:on_finished()
  -- Nothing.
end

function inventory_submenu:on_draw(dst_surface)

  local cell_size = 28
  local cell_spacing = 4

  local width, height = dst_surface:get_size()
  local center_x = width / 2
  local center_y = height / 2
  local menu_x, menu_y = center_x - self.width / 2, center_y - self.height / 2

  -- Draw the background.
  self:draw_background(dst_surface)
  
  -- Draw the cursor caption.
  self:draw_caption(dst_surface)

  -- Draw each inventory static item.
  local y = menu_y + 84
  local k = 0
  local x = menu_x + 64
  for j = 0, 4 do
    k = k + 1
    local item = self.game:get_item(item_names_static[k])
    if item:get_variant() > 0 then
      -- The player has this item: draw it.
      self.sprites_static[k]:draw(dst_surface, x, y)
    end
    -- Next item position (they are on the same column).
    if j < 3 then
      y = y + cell_size + cell_spacing
    else
      x = x + cell_size + cell_spacing
    end
    
  end

  -- Draw each inventory assignable item.
  local y = menu_y + 84
  local k = 0

  for i = 0, 3 do
    local x = menu_x + 96
    for j = 0, 2 do
      if i == 3 and j == 0 then
        x = x + cell_size + cell_spacing
      end
      k = k + 1
      if item_names_assignable[k] ~= nil then
        local item = self.game:get_item(item_names_assignable[k])
        if item:get_variant() > 0 then
          -- The player has this item: draw it.
          self.sprites_assignables[k]:set_direction(item:get_variant() - 1)
          self.sprites_assignables[k]:draw(dst_surface, x, y)
          if self.counters[k] ~= nil then
            self.counters[k]:draw(dst_surface, x + 8, y)
          end
        end
      end
      x = x + cell_size + cell_spacing
    end
    y = y + cell_size + cell_spacing
  end

  -- Draw ocarina menu.
  if self.menu_ocarina == true then
    local menu_ocarina_img = sol.surface.create("menus/pause/inventory/ocarina_background.png")
    menu_ocarina_img:draw_region(0, 0, 98, 34, dst_surface, menu_x + 174, menu_y + 62) 
    local melody = self.game:get_item("melody_1")
    if melody:get_variant() > 0 then
      local menu_ocarina_img_1 = sol.surface.create("menus/pause/inventory/ocarina_1.png")
      menu_ocarina_img_1:draw_region(0, 0, 98, 34, dst_surface, menu_x + 184, menu_y + 72) 
    end
    local melody = self.game:get_item("melody_2")
    if melody:get_variant() > 0 then
      local menu_ocarina_img_2 = sol.surface.create("menus/pause/inventory/ocarina_2.png")
      menu_ocarina_img_2:draw_region(0, 0, 98, 34, dst_surface, menu_x + 216, menu_y + 72)
    end
    local melody = self.game:get_item("melody_2")
    if melody:get_variant() > 0 then
      local menu_ocarina_img_3 = sol.surface.create("menus/pause/inventory/ocarina_3.png")
      menu_ocarina_img_3:draw_region(0, 0, 98, 34, dst_surface, menu_x + 248, menu_y + 72)
  end
  end

  -- Draw cursor only when the save dialog is not displayed.
  if not self.dialog_opened then
    self.cursor_sprite:draw(dst_surface, menu_x + 64 + 32 * self.cursor_column, menu_y + 79 + 32 * self.cursor_row)
  end

  -- Draw the item being assigned if any.
  if self:is_assigning_item() then
    self.item_assigned_sprite:draw(dst_surface)
  end

end

function inventory_submenu:on_command_pressed(command)
  local handled = submenu.on_command_pressed(self, command)

  if not handled then

    if command == "action"  then
      if self.game:get_command_effect("action") == nil and self.game:get_custom_command_effect("action") == "info" then
        if not self.dialog_opened then
          handled = true
          self:show_info_message()
        else
          handled = false
        end
      end

    elseif command == "item_1" then
      if self:is_item_selected() or (self.cursor_row == 0 and self.cursor_column > 3)  then
        self:assign_item(1)
        handled = true
      end
    elseif command == "item_2" then
      if self:is_item_selected()  or (self.cursor_row == 0 and self.cursor_column > 3) then
        self:assign_item(2)
        handled = true
      end
    elseif command == "left"  then
      if self.cursor_column == 0 then
        self:previous_submenu()
      else
        audio_manager:play_sound("menus/menu_cursor")
        self:set_cursor_position(self.cursor_row, self.cursor_column - 1)
      end
      handled = true

    elseif command == "right"  then
      local limit = 3
      if self.menu_ocarina == true and self.cursor_row == 0 then
        limit = 6
      end
      if self.cursor_column == limit then
        self:next_submenu()
      else
        audio_manager:play_sound("menus/menu_cursor")
        self:set_cursor_position(self.cursor_row, self.cursor_column + 1)
      end
      handled = true

    elseif command == "up" and self.cursor_column < 4 then
      audio_manager:play_sound("menus/menu_cursor")
      self:set_cursor_position((self.cursor_row + 3) % 4, self.cursor_column)
      handled = true

    elseif command == "down" and self.cursor_column < 4 then
      audio_manager:play_sound("menus/menu_cursor")
      self:set_cursor_position((self.cursor_row + 1) % 4, self.cursor_column)
      handled = true

    end
  end

  return handled

end

-- Shows a message describing the item currently selected.
-- The player is supposed to have this item.
function inventory_submenu:show_info_message()
  local item_name = self:get_item_name(self.cursor_row, self.cursor_column)
  local variant = self.game:get_item(item_name):get_variant()
  local dialog_id = "scripts.menus.pause_inventory." .. item_name .. "." .. variant
  self:show_info_dialog(dialog_id, function()
    -- Re-update the cursor and buttons.
    self:set_cursor_position(self.cursor_row, self.cursor_column)  
  end)
end

function inventory_submenu:set_cursor_position(row, column)
  self.cursor_row = row
  self.cursor_column = column
  local index
  local item_name
  self.game:set_value("pause_inventory_last_item_index", index)

  -- Update the caption text and the action icon.
  local item_name = self:get_item_name(row, column)
  local item = item_name and self.game:get_item(item_name) or nil
  local variant = item and item:get_variant()
  local item_icon_opacity = 128
  if variant > 0 then
    self:set_caption_key("inventory.caption.item." .. item_name .. "." .. variant)
    self.game:set_custom_command_effect("action", "info")
    if item:is_assignable() then
      self.game:set_hud_mode("normal")
    else
      self.game:set_hud_mode("pause")
    end
  else
    self:set_caption_key(nil)
    self.game:set_custom_command_effect("action", nil)
    self.game:set_hud_mode("pause")
  end

end

function inventory_submenu:get_item_name(row, column)

    if column > 0 and column < 4 then
      if row == 3 and column == 1 then
        item_name = item_names_static[5]
      elseif row == 3 and column > 1 then
        index = row * 3 + column - 1
        item_name = item_names_assignable[index]
      else
        index = row * 3 + column - 1
        item_name = item_names_assignable[index + 1]
      end
      
   elseif column == 4 then
      item_name = "melody_1"
   elseif column == 5 then
      item_name = "melody_2"
   elseif column == 6 then
      item_name = "melody_3"
   else
      index = row 
      item_name = item_names_static[index + 1]
  end

  return item_name

end

function inventory_submenu:is_item_selected()

  local item_name = self:get_item_name(self.cursor_row, self.cursor_column)

  return self.game:get_item(item_name):get_variant() > 0

end

-- Assigns the selected item to a slot (1 or 2).
-- The operation does not take effect immediately: the item picture is thrown to
-- its destination icon, then the assignment is done.
-- Nothing is done if the item is not assignable.
function inventory_submenu:assign_item(slot)

  local item_name = self:get_item_name(self.cursor_row, self.cursor_column)
  local item = self.game:get_item(item_name)
  local assignable = false

  -- If this item is not assignable, do nothing.
  if not item:is_assignable() then
    return
  end
  -- If another item is being assigned, finish it immediately.
  if self:is_assigning_item() then
    self:finish_assigning_item()
  end
  if item_name == "ocarina" or (self.cursor_row == 0 and self.cursor_column > 3) then
     if self.menu_ocarina == true then
        if self.cursor_row == 0 and self.cursor_column > 3 then
              assignable = true
        else
          self.cursor_column = 3
          self.menu_ocarina = false
        end
      else
        local melody_1 = self.game:get_item("melody_1")
        local melody_2 = self.game:get_item("melody_2")
        local melody_3 = self.game:get_item("melody_3")
        if melody_1:get_variant() > 0 or melody_2:get_variant() > 0 or melody_3:get_variant() > 0 then
          self.menu_ocarina = true
        else
          assignable = true
        end
      end
  else
    assignable = true
  end

  if assignable then
    -- Memorize this item.
      self.item_assigned = item
      self.item_assigned_sprite = sol.sprite.create("entities/items")
      self.item_assigned_sprite:set_animation(item_name)
      self.item_assigned_sprite:set_direction(item:get_variant() - 1)
      self.item_assigned_destination = slot

      -- Play the sound.
      audio_manager:play_sound("menus/menu_select")

      -- Compute the movement.
      local x1 = 63 + 32 * self.cursor_column
      local y1 = 90 + 32 * self.cursor_row

      local x2 = (slot == 1) and 20 or 72
      local y2 = 46

      self.item_assigned_sprite:set_xy(x1, y1)
      local movement = sol.movement.create("target")
      movement:set_target(x2, y2)
      movement:set_speed(300)
      movement:start(self.item_assigned_sprite, function()
        self:finish_assigning_item()
      end)
  end

end

-- Returns whether an item is currently being thrown to an icon.
function inventory_submenu:is_assigning_item()

  return self.item_assigned_sprite ~= nil

end

-- Stops assigning the item right now.
-- This function is called when we want to assign the item without
-- waiting for its throwing movement to end, for example when the inventory submenu
-- is being closed.
function inventory_submenu:finish_assigning_item()

  -- If the item to assign is already assigned to the other icon, switch both items.
  local slot = self.item_assigned_destination
  local current_item = self.game:get_item_assigned(slot)
  local other_item = self.game:get_item_assigned(3 - slot)

  if other_item == self.item_assigned then
    self.game:set_item_assigned(3 - slot, current_item)
  end
  self.game:set_item_assigned(slot, self.item_assigned)

  self.item_assigned_sprite:stop_movement()
  self.item_assigned_sprite = nil
  self.item_assigned = nil

end

return inventory_submenu
