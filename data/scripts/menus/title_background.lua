-- Animated background for the title screen and the file selection menu.

local title_background = {}

function title_background:on_started()

  self.surface_w = 320
  self.surface_h = 256
  self.surface = sol.surface.create(self.surface_w, self.surface_h)
  self.background = sol.surface.create("menus/title_screen/tmp_background.png")
  
  self.fade_surface = sol.surface.create(self.surface_w, self.surface_h)
  self.fade_surface:fill_color({0, 0, 0})

  self.mountain_clouds = sol.sprite.create("menus/title_screen/mountain_clouds")
  self.wreck = sol.sprite.create("menus/title_screen/wreck")
  self.floating_wood = sol.sprite.create("menus/title_screen/floating_wood")
  self.wave_big = sol.sprite.create("menus/title_screen/wave_big")
  self.wave_small = sol.sprite.create("menus/title_screen/wave_small")
  self.swell = sol.sprite.create("menus/title_screen/swell")
    
  self.anim_length = 10000
  self.anim_delta = 10
  self.elapsed_time = 0

  -- Preload sounds
  sol.audio.preload_sounds()
 
  -- Launch animation.
  self:set_phase("begin")

end

function title_background:launch_animation()

  self.elapsed_time = 0

  self.timer = sol.timer.start(self, self.anim_delta, function()
    -- Elapsed time since launch of animation.
    self.elapsed_time = self.elapsed_time + self.anim_delta
    
    if self.elapsed_time < self.anim_length then
      -- Keep on updating while time is remaining.
      return true
    else
      self.phase = "end"
      self.timer:stop()
      
      -- Call the callback when the animation is finished.
      if self.callback ~= nil then
        self.callback()
      end

      -- Stop the timer.
      return false
    end
  end)

end

function title_background:on_draw(dst_surface)

  local width, height = dst_surface:get_size()
  
  -- Rebuild surface.
  self.surface:clear()

  -- Background.
  local y_offset = math.floor(self:get_y_offset(self.elapsed_time))
  self.background:draw(self.surface, 0, y_offset)

  -- Sprites.
  self.mountain_clouds:draw(self.surface, 40, 118 + y_offset)
  self.wreck:draw(self.surface, 152, 452 + y_offset)
  self.floating_wood:draw(self.surface, 208, 488 + y_offset)
  self.floating_wood:draw(self.surface, 280, 464 + y_offset)
  for i = 1, 10 do
    self.swell:draw(self.surface, (i - 1) * 32, 440 + y_offset)
  end
  self.wave_big:draw(self.surface, 72, 464 + y_offset)
  self.wave_big:draw(self.surface, 224, 464 + y_offset)
  self.wave_big:draw(self.surface, 120, 488 + y_offset)
  self.wave_big:draw(self.surface, 300, 488 + y_offset)
  self.wave_big:draw(self.surface, 10, 476 + y_offset)
  self.wave_small:draw(self.surface, 128, 460 + y_offset)
  self.wave_small:draw(self.surface, 256, 484 + y_offset)

  --if self.phase ~= "end" then
    self.fade_surface:draw(dst_surface, (width - self.surface_w)/ 2, (height - self.surface_h) / 2)
  --end

  -- Draw surface on destination.
  self.surface:draw(dst_surface, (width - self.surface_w)/ 2, (height - self.surface_h) / 2)

end

function title_background:get_y_offset(t)

  local b = -256
  local c = 256
  local d = self.anim_length

  if c == 0 or t >= d then
    return b + c
  end

  t = t / d * 2
  if t < 1 then
    return c / 2 * math.pow(t, 5) + b
  else
    t = t - 2
    return c / 2 * (math.pow(t, 5) + 2) + b
  end

end

function title_background:set_phase(phase)

  if self.timer ~= nil then
    self.timer:stop()
  end

  if phase == "begin" then
    self.phase = "begin"
    self.elapsed_time = 0
    self:launch_animation()
  else
    self.elapsed_time = self.anim_length
    self.phase = "end"
  end

end

function title_background:on_key_pressed(key)
  return false
end

function title_background:show(context, callback)
  
  sol.menu.start(context, self, true)
  self.callback = callback

end

return title_background
