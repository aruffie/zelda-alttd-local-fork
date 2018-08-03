-- Animated Zeldaforce logo by Olivier Cléro.
-- Version 1.0

local zeldaforce_logo_menu = {}

----------------------------------------------------------

-- Starting the menu.
function zeldaforce_logo_menu:on_started()

  -- Surface.
  self.surface_w = 320
  self.surface_h = 240
  self.surface = sol.surface.create(self.surface_w, self.surface_h)

  -- Load images.
  local logo_w = 96
  local logo_h = 70
  local logo_x = (self.surface_w - logo_w) / 2
  local logo_y = (self.surface_h - logo_h) / 2

  self.logo_Z = {
    surface = sol.surface.create("menus/zeldaforce_logo/zeldaforce_logo_z.png"),
    pos_begin = {
      x = -logo_w,
      y = logo_y,
    },
    pos_end = {
      x = logo_x,
      y = logo_y,
    },
  }

  self.logo_F = {
    surface = sol.surface.create("menus/zeldaforce_logo/zeldaforce_logo_f.png"),
    pos_begin = {
      x = self.surface_w,
      y = logo_y,
    },
    pos_end = {
      x = logo_x,
      y = logo_y,
    },
  }
  
  self.triforce_top = {
    surface = sol.surface.create("menus/zeldaforce_logo/zeldaforce_logo_triforce_top.png"),
    pos_begin = {
      x = logo_x,
      y = -logo_h,
    },
    pos_end = {
      x = logo_x,
      y = logo_y,
    },
  }

  self.triforce_left = {
    surface = sol.surface.create("menus/zeldaforce_logo/zeldaforce_logo_triforce_left.png"),
    pos_begin = {
      x = -logo_w,
      y = logo_y,
    },
    pos_end = {
      x = logo_x,
      y = logo_y,
    },
  }

  self.triforce_right = {
    surface = sol.surface.create("menus/zeldaforce_logo/zeldaforce_logo_triforce_right.png"),
    pos_begin = {
      x = self.surface_w,
      y = logo_y,
    },
    pos_end = {
      x = logo_x,
      y = logo_y,
    },
  }

  self.triforce_middle_surface = sol.surface.create("menus/zeldaforce_logo/zeldaforce_logo_triforce_middle.png")
  self.draw_triforce_middle = false
  
  -- Start timer.
  self.anim_length = 1200
  self.elapsed_time = 0
  self.anim_delta = 25
  
  -- Start.
  self.stopped = false
  self:step2()

end

-- Draws this menu on the quest screen.
function zeldaforce_logo_menu:on_draw(dst_surface)

  -- Simply draws the surface at the center of the screen.
  local dst_w, dst_h = dst_surface:get_size()
  self.surface:draw(dst_surface, (dst_w - self.surface_w) / 2, (dst_h - self.surface_h) / 2)

end

-- Called when a keyboard key is pressed.
function zeldaforce_logo_menu:on_key_pressed(key)

  if key == "escape" then
    -- Escape: quit Solarus.
    sol.main.exit()
    return true
  elseif not self.stopped then
    self.stopped = true

    -- Stop the timer.
    if self.timer ~= nil then
      self.timer:stop()
      self.timer = nil
    end

    -- Go directly to last step
    if self.step < 3 then
      sol.audio.play_sound("solarus_logo")
      self:step4()
      self:step5(500)
    return true
    end

  end
  
  return false
end

----------------------------------------------------------

-- Step 1: Triforce 
function zeldaforce_logo_menu:step2()

  self.step = 2
  self.has_played_sound = false

  -- Update the surface.
  self:update_surface()

  -- Start animation.
  self.timer = sol.timer.start(self.anim_delta, function()
    -- Elapsed time since launch of animation.
    self.elapsed_time = self.elapsed_time + self.anim_delta
    
    -- Update the surface.
    self:update_surface()

    -- Play a sound for the collision.
    if self.elapsed_time >= self.anim_length * 0.6 and not self.has_played_sound then
      self.has_played_sound = true
      sol.audio.play_sound("solarus_logo")
    end

    if self.elapsed_time < self.anim_length then
      -- Keep on updating while time is remaining.
      return true
    else
      -- At the end of the animation, start the next step.
      self.timer:stop()
      self:step3()
    end
  end)

end

-- Step 3: Letters Z and F.
function zeldaforce_logo_menu:step3()
  
  self.step = 3
  self.has_played_sound = false

  -- Reset elapsed time.
  self.elapsed_time = 0

  -- Update the surface.
  self:update_surface()

  -- Start animation.
  self.timer = sol.timer.start(self.anim_delta, function()
    -- Elapsed time since launch of animation.
    self.elapsed_time = self.elapsed_time + self.anim_delta
    
    -- Update the surface.
    self:update_surface()

    -- Play a sound for the collision.
    if self.elapsed_time >= self.anim_length * 0.6 and not self.has_played_sound then
      self.has_played_sound = true
      self.draw_triforce_middle = true
      sol.audio.play_sound("solarus_logo")
    end

    if self.elapsed_time < self.anim_length then
      -- Keep on updating while time is remaining.
      return true
    else
      -- At the end of the animation, start the next step.
      self.timer:stop()
      --sol.audio.play_sound("sword_spin_attack_load")
      self:step4()

      -- Wait a bit before quitting the menu.
      self:step5(500)
    end
  end)

end

-- Step 4: No animation.
function zeldaforce_logo_menu:step4()

  self.step = 4

  -- Update the surface.
  self:update_surface()

end

-- Step 5: Quit this menu.
function zeldaforce_logo_menu:step5(fadeout_wait_time)

  if not sol.menu.is_started(self) then
    return
  end

  self.step = 5

  sol.timer.start(self, fadeout_wait_time, function()
    self.surface:fade_out()
    sol.timer.start(self, 1000, function()
      sol.menu.stop(self)
    end)
  end)
end

-- Updates the surface according to the current step.
function zeldaforce_logo_menu:update_surface()
  
  if self.step == 2 then

    -- Clear the surface.
    self.surface:clear()

    -- Draw triforce, moving frame by frame.
    self:draw_item(self.surface, self.triforce_top, self.elapsed_time, self.anim_length)
    self:draw_item(self.surface, self.triforce_left, self.elapsed_time, self.anim_length)
    self:draw_item(self.surface, self.triforce_right, self.elapsed_time, self.anim_length)
    
  elseif self.step == 3 then
    
    -- Clear the surface.
    self.surface:clear()
    
    -- Draw triforce, still.
    -- Draw the middle of the triforce.
    if self.draw_triforce_middle then
      self.triforce_middle_surface:draw(self.surface, self.triforce_top.pos_end.x, self.triforce_top.pos_end.y)    
    end
    self:draw_item(self.surface, self.triforce_top, 0, 0)
    self:draw_item(self.surface, self.triforce_left, 0, 0)
    self:draw_item(self.surface, self.triforce_right, 0, 0)

    -- Draw letters, moving frame by frame.
    self:draw_item(self.surface, self.logo_Z, self.elapsed_time, self.anim_length)
    self:draw_item(self.surface, self.logo_F, self.elapsed_time, self.anim_length)
  
  elseif self.step == 4 then
    
    -- Clear the surface.
    self.surface:clear()

    -- Draw triforce, still.
    self.triforce_middle_surface:draw(self.surface, self.triforce_top.pos_end.x, self.triforce_top.pos_end.y)    
    self:draw_item(self.surface, self.triforce_top, 0, 0)
    self:draw_item(self.surface, self.triforce_left, 0, 0)
    self:draw_item(self.surface, self.triforce_right, 0, 0)

    -- Draw letters, still.
    self:draw_item(self.surface, self.logo_Z, 0, 0)
    self:draw_item(self.surface, self.logo_F, 0, 0)
  
  end
end

function zeldaforce_logo_menu:draw_item(dst_surface, item, elapsed_time, total_time)

  local x = self:get_easing_value(
    elapsed_time, 
    item.pos_begin.x,
    item.pos_end.x - item.pos_begin.x,
    total_time
  )

  local y = self:get_easing_value(
    elapsed_time, 
    item.pos_begin.y,
    item.pos_end.y - item.pos_begin.y,
    total_time
  )

  item.surface:draw(dst_surface, x, y)

end

-- Quintic easing in out function:
-- t = elapsed time
-- b = begin
-- c = change == ending - beginning
-- d = duration (total time)
function zeldaforce_logo_menu:get_easing_value(t, b, c, d)

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

----------------------------------------------------------

-- Return the menu to the caller.
return zeldaforce_logo_menu
