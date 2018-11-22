-- Logo and texts on the title screen (no background here).
-- Author: Olivier Cléro (oclero@hotmail.com)

local language_manager = require("scripts/language_manager")
local text_fx_helper = require("scripts/text_fx_helper")
local audio_manager = require("scripts/audio_manager")

local title_logo = {}

function title_logo:on_started()

  -- Initialize surface.
  self.surface_w = 320
  self.surface_h = 256
  self.surface = sol.surface.create(self.surface_w, self.surface_h)

  -- Sprites.
  self.zelda_logo_sprite = sol.sprite.create("menus/title_screen/title_zelda")
  self.zelda_logo_sprite:set_animation("default")

  self.la_logo_sprite = sol.sprite.create("menus/title_screen/title_la")
  self.la_logo_sprite:set_animation("default")

  self.alttd_logo_sprite = sol.sprite.create("menus/title_screen/title_alttd")
  self.alttd_logo_sprite:set_animation("default")

  -- Texts
  local font, font_size = language_manager:get_menu_font()
  local center_x, center_y = self.surface_w / 2, self.surface_h / 2
  self.copyright_text = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    font = "04b03",
    font_size = 8,
    text_key = "title_screen.copyright",
    color = {255, 255, 255},
  }
  self.copyright_text:set_xy(center_x, self.surface_h - 16)

  self.press_space_text = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    font = font,
    font_size = font_size,
    text_key = "title_screen.press_space",
    color = {255, 255, 255},
  }
  self.press_space_text:set_xy(center_x, self.surface_h - 80)

  -- Make the "Press space" text clip every 500ms.
  self.show_press_space = false
  function switch_press_space()
    self.show_press_space = not self.show_press_space
    sol.timer.start(self, 500, switch_press_space)
  end
  switch_press_space()

  -- Allow to skip the menu after a delay.
  self.allow_skip = false
  sol.timer.start(self, 500, function()
    self.allow_skip = true
  end)

  -- Initialization.
  self.phase = 0

  -- Launch animations.
  sol.timer.start(self, 100, function()
    self:set_phase(1)
  end)
end

function title_logo:on_draw(dst_surface)

  -- Rebuild surface.
  self.surface:clear()

  -- Copyright.
  text_fx_helper:draw_text_with_shadow(self.surface, self.copyright_text, {0, 0, 112})
  
  -- Draw the logo's different parts.
  if self.phase >= 1 then
    self.zelda_logo_sprite:draw(self.surface, 84, 17)
    
    if self.phase >= 2 then
      self.la_logo_sprite:draw(self.surface, 128, 72)
      
      if self.phase >= 3 then
        self.alttd_logo_sprite:draw(self.surface, 111, 85)
        
        if self.phase >= 4 and self.show_press_space then
          text_fx_helper:draw_text_with_stroke(self.surface, self.press_space_text, {0, 0, 112})
        end
      end
    end
  end

  -- Draw on destination surface.
  local width, height = dst_surface:get_size()
  self.surface:draw(dst_surface, (width - self.surface_w) / 2, (height - self.surface_h) / 2)

end

function title_logo:on_key_pressed(key)

  if key == "space" or key == "return" then
    if self.timer ~= nil then
      self.timer:stop()
    end
    
    handled = true
    sol.menu.stop(self)
  end

  return false
end

function title_logo:on_joypad_button_pressed(button)

  return title_logo:on_key_pressed("space")

end

-- Modify the phase (parts of the final logo appear one after another).
function title_logo:set_phase(phase)
  if phase ~= self.phase then
    self.phase = phase
    
    if phase == 1 then
      -- Phase 1: Zelda logo.
      self.zelda_logo_sprite:set_animation("shining")
      self.zelda_logo_sprite:fade_in(10)

      -- Go to next phase.
      sol.timer.start(self, 1500, function()
        self:set_phase(self.phase + 1)
      end)

    elseif phase == 2 then
      -- Phase 2: Link's Awakening logo.
      self.la_logo_sprite:set_animation("appearing")
      self.la_logo_sprite:fade_in(20)

      -- Go to next phase.
      sol.timer.start(self, 1000, function()
        self:set_phase(self.phase + 1)
      end)

    elseif phase == 3 then
      -- Phase 3: A Link To The Dream logo.
      self.alttd_logo_sprite:set_animation("filling")
      self.alttd_logo_sprite:fade_in(10)

      -- Go to next phase.
      sol.timer.start(self, 1000, function()
        self:set_phase(self.phase + 1)
      end)

    elseif phase == 4 then
      -- The Zelda logo shines every 10 seconds.
      sol.timer.start(self, 10000, function()
        self.zelda_logo_sprite:set_animation("shining")
        return true
      end)
    end
  end
end

return title_logo
