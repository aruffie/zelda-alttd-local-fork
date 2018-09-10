-- Logo and texts on the title screen (no background).

local title_logo = {}

function title_logo:on_started()

  self.surface_w = 320
  self.surface_h = 256
  self.surface = sol.surface.create(self.surface_w, self.surface_h)

  self.zelda_logo_sprite = sol.sprite.create("menus/title_screen/title_zelda")
  self.zelda_logo_sprite:set_animation("shining")
  self.zelda_logo_sprite:fade_in(10)

end

function title_logo:on_draw(dst_surface)

  -- Rebuild surface.
  self.surface:clear()

  self.zelda_logo_sprite:draw(self.surface, 84, 17)

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

return title_logo

