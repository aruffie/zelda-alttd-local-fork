local submenu = require("menus/pause_submenu")
local quest_status_submenu = submenu:new()

function quest_status_submenu:on_started()

  submenu.on_started(self)
  self.quest_items_surface = sol.surface.create(320, 240)
  self.cursor_sprite = sol.sprite.create("menus/pause_cursor")
  self.cursor_sprite_x = 0
  self.cursor_sprite_y = 0
  self.cursor_position = nil
  self.caption_text_keys = {}

  local item_sprite = sol.sprite.create("entities/items")

  -- Draw the items on a surface.
  self.quest_items_surface:set_transparency_color{0, 0, 0}
  self.quest_items_surface:fill_color{0, 0, 0}

  -- Pieces of heart.
  local pieces_of_heart_img = sol.surface.create("menus/quest_status_pieces_of_heart.png")
  local x = 51 * (self.game:get_value("i1030") or 0)
  pieces_of_heart_img:draw_region(x, 0, 51, 50, self.quest_items_surface, 101, 81)
  self.caption_text_keys[4] = "quest_status.caption.pieces_of_heart"

  -- Dungeons finished
  local dungeons_img = sol.surface.create("menus/quest_status_dungeons.png")
  local dst_positions = {
    { 209,  69 },
    { 232,  74 },
    { 243,  97 },
    { 232, 120 },
    { 209, 127 },
    { 186, 120 },
    { 175,  97 },
    { 186,  74 },
  }
  for i, dst_position in ipairs(dst_positions) do
    if self.game:is_dungeon_finished(i) then
      dungeons_img:draw_region(20 * (i - 1), 0, 20, 20,
          self.quest_items_surface, dst_position[1], dst_position[2])
    end
  end

  -- Cursor.
  self:set_cursor_position(0)
end

function quest_status_submenu:set_cursor_position(position)

  if position ~= self.cursor_position then
    self.cursor_position = position
    if position <= 3 then
      self.cursor_sprite_x = 68
    elseif position == 4 then
      self.cursor_sprite_x = 126
      self.cursor_sprite_y = 107
    else
      self.cursor_sprite_x = 15 + 34 * position
    end

    if position == 0 then
      self.cursor_sprite_y = 79
    elseif position == 1 then
      self.cursor_sprite_y = 108
    elseif position == 2 then
      self.cursor_sprite_y = 138
    elseif position == 4 then
      self.cursor_sprite_y = 107
    else
      self.cursor_sprite_y = 172
    end

    self:set_caption(self.caption_text_keys[position])
  end
end

function quest_status_submenu:on_command_pressed(command)

  local handled = submenu.on_command_pressed(self, command)

  if not handled then

    if command == "left" then
      if self.cursor_position <= 3 then
        self:previous_submenu()
      else
        sol.audio.play_sound("cursor")
        if self.cursor_position == 4 then
          self:set_cursor_position(0)
        elseif self.cursor_position == 5 then
          self:set_cursor_position(3)
        else
          self:set_cursor_position(self.cursor_position - 1)
        end
      end
      handled = true

    elseif command == "right" then
      if self.cursor_position == 4 or self.cursor_position == 7 then
        self:next_submenu()
      else
        sol.audio.play_sound("cursor")
        if self.cursor_position <= 2 then
          self:set_cursor_position(4)
        elseif self.cursor_position == 3 then
          self:set_cursor_position(5)
        else
          self:set_cursor_position(self.cursor_position + 1)
        end
      end
      handled = true

    elseif command == "down" then
      sol.audio.play_sound("cursor")
      self:set_cursor_position((self.cursor_position + 1) % 8)
      handled = true

    elseif command == "up" then
      sol.audio.play_sound("cursor")
      self:set_cursor_position((self.cursor_position + 7) % 8)
      handled = true
    end

  end

  return handled
end

function quest_status_submenu:on_draw(dst_surface)

  local width, height = dst_surface:get_size()
  local x = width / 2 - 160
  local y = height / 2 - 120
  self:draw_background(dst_surface)
  self:draw_caption(dst_surface)
  self.quest_items_surface:draw(dst_surface, x, y)
  self.cursor_sprite:draw(dst_surface, x + self.cursor_sprite_x, y + self.cursor_sprite_y)
  self:draw_save_dialog_if_any(dst_surface)
end

return quest_status_submenu

