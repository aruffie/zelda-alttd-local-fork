-- Animated background for the title screen and the file selection menu.

local title_background = {}

-- Called when this menu is started.
function title_background:on_started()

  -- This menu is build for a 320x256 pixels size.
  self.surface_w = 320
  self.surface_h = 256
  self.surface = sol.surface.create(self.surface_w, self.surface_h)
  self.sky = sol.surface.create("menus/title_screen/sky.png")
  self.background = sol.surface.create("menus/title_screen/tmp_background.png")
  
  -- Surface used for fading to black, at the end.
  self.fade_surface = sol.surface.create(self.surface_w, self.surface_h)
  self.fade_surface:fill_color({0, 0, 0})

  -- We don't use a map but rather place manually sprites on the background
  -- and move them manually. The reason is to make this cutscene usable as a
  -- simple menu anywhere and anyhow.
  self.clouds = sol.sprite.create("menus/title_screen/clouds")
  self.mountain_clouds = sol.sprite.create("menus/title_screen/mountain_clouds")
  self.wreck = sol.sprite.create("menus/title_screen/wreck")
  self.floating_wood = sol.sprite.create("menus/title_screen/floating_wood")
  self.wave_big = sol.sprite.create("menus/title_screen/wave_big")
  self.wave_small = sol.sprite.create("menus/title_screen/wave_small")
  self.swell = sol.sprite.create("menus/title_screen/swell")
    
  -- Animation length configuration.
  self.anim_length = 4000 --ms
  self.anim_delta = 1000 / 60 -- ms
  self.elapsed_time = 0 -- Modified automatically by this script.

  -- Preload sounds.
  sol.audio.preload_sounds()
 
  -- Launch animation.
  self:set_phase("begin")

end

-- Start the camera animation.
function title_background:launch_animation()

  -- Restart the animation.
  self.elapsed_time = 0

  -- We use a timer called each anim_delta milliseconds.
  -- The timer is called in a loop while the total length
  -- is below the defined final length.
  self.timer = sol.timer.start(self, self.anim_delta, function()
    -- Elapsed time since launch of animation.
    self.elapsed_time = self.elapsed_time + self.anim_delta
    
    if self.elapsed_time < self.anim_length then
      -- Keep on updating while time is remaining.
      -- Relaunch the timer once again.
      return true
    else
      -- No time is remaining. We stop the animation.
      self.elapsed_time = self.anim_length
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

-- Called when this menu has to draw on the screen.
function title_background:on_draw(dst_surface)

  -- Get the final surface size.
  local width, height = dst_surface:get_size()
  
  -- Rebuild surface.
  self.surface:clear()

  -- Background.
  local y_offset = math.floor(self:get_y_offset(self.elapsed_time))
  self.sky:draw(self.surface, 0, 0)
  self.background:draw(self.surface, 0, y_offset)

  -- Sprites are placed manually since this is not a map.
  self.clouds:draw(self.surface, 0, 0 + y_offset)
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

-- We move the camera with a non-linear movement. Since it is not available
-- in Solarus at the time this script was written, the camera movement is
-- made manually, based on a easing function. 
function title_background:get_y_offset(t)

  
  local end_y = 0 
  local begin_y = -256
  local delta = end_y - begin_y
  
  if self.phase == "end" or t >= self.anim_length then
    return end_y
  end

  t = t / self.anim_length * 2
  if t < 1 then
    return delta / 2 * math.pow(t, 2) + begin_y
  else
    return -delta / 2 * ((t - 1) * (t - 3) - 1) + begin_y
  end
end

-- Change the phase of the cutscene.
-- Possible phases (in order):
-- 1. "begin"
-- 2. "moving"
-- 3. "end"
function title_background:set_phase(phase)

  if self.timer ~= nil then
    self.timer:stop()
  end

  if phase == "begin" then
    self.phase = phase
    self.elapsed_time = 0
    self.timer = sol.timer.start(self, 500, function()
      self:set_phase("moving")
    end)
  elseif phase == "moving" then    
    self.phase = phase
    self.elapsed_time = 0
    self:launch_animation()
  elseif phase == "end" then
    self.phase = phase
    self.elapsed_time = self.anim_length
  end

end

-- The cutscene is just a background, and does not use any keyboard event.
function title_background:on_key_pressed(key)
  return false
end

-- Show this animated background and call the callback when the camera
-- movement is finished.
function title_background:show(context, callback)
  
  sol.menu.start(context, self, true)
  self.callback = callback

end

return title_background
