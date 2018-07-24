-- Animated Zeldaforce logo by Olivier Cléro.
-- Version 1.0

local zeldaforce_logo_menu = {}

-- Quintic easing in out function:
-- t = elapsed time
-- b = begin
-- c = change == ending - beginning
-- d = duration (total time)
local function get_easing_value(t, b, c, d)

  t = t / d * 2
  if t < 1 then
    return c / 2 * math.pow(t, 5) + b
  else
    t = t - 2
    return c / 2 * (math.pow(t, 5) + 2) + b
  end

end

-- Starting the menu.
function zeldaforce_logo_menu:on_started()

  self.surface_w = 320
  self.surface_h = 240
  self.surface = sol.surface.create(self.surface_w, self.surface_h)

  -- Load images.
  self.logo_z = sol.surface.create("menus/zeldaforce_logo/zeldaforce_logo_z.png")
  self.logo_f = sol.surface.create("menus/zeldaforce_logo/zeldaforce_logo_f.png")
  self.logo_triforce = sol.surface.create("menus/zeldaforce_logo/zeldaforce_logo_triforce.png")

  -- Start timer.
  self.anim_length = 1200
  self.elapsed_time = 0
  self.anim_delta = 25
  
  -- Start.
  self:step1()

end

function zeldaforce_logo_menu:step1()

  self.step = 1

  -- Black screen during a small amount of time.
  --self.timer = sol.timer.start(self, 50, function()
    self:step2()
  --end)

end

function zeldaforce_logo_menu:step2()
  
  self.step = 2

  -- Update the surface.
  self:update_surface()

  -- Then start animation.
  self.timer = sol.timer.start(self.anim_delta, function()

    -- Elpased time since launch of animation.
    self.elapsed_time = self.elapsed_time + self.anim_delta
    
    -- Update the surface.
    self:update_surface()

    -- Keep on updating while time is remaining.
    return self.elapsed_time < self.anim_length
  end)

  -- At the end of the animation, start the next step.
  self.timer2 = sol.timer.start(self.anim_length, function()
    
    sol.audio.play_sound("sword_spin_attack_load")
    self:step3()

    -- Wait a bit before quitting the menu.
    self:begin_quit(1500)

  end)

end

function zeldaforce_logo_menu:step3()

  self.step = 3

  -- Update the surface.
  self:update_surface()

end

function zeldaforce_logo_menu:begin_quit(fadeout_wait_time)
  sol.timer.start(self, fadeout_wait_time, function()
    self.surface:fade_out()
    sol.timer.start(self, 1000, function()
      sol.menu.stop(self)
    end)
  end)
end

-- Draws this menu on the quest screen.
function zeldaforce_logo_menu:on_draw(dst_surface)

  -- Simply draws the surface at the center of the screen.
  local dst_w, dst_h = dst_surface:get_size()
  self.surface:draw(dst_surface, (dst_w - self.surface_w) / 2, (dst_h - self.surface_h) / 2)

end

-- Updates the surface according to the current step.
function zeldaforce_logo_menu:update_surface()
  
  if self.step == 2 then
    
    -- Clear the surface.
    self.surface:clear()

    -- Compute each letter's coordinates.
    local logo_w, logo_h = self.logo_z:get_size()
    local logo_z_begin_x = -logo_w
    local end_x = (self.surface_w - logo_w) / 2
    local logo_z_x = get_easing_value(self.elapsed_time, logo_z_begin_x, end_x - logo_z_begin_x, self.anim_length)
    local logo_y = (self.surface_h - logo_h) / 2
    local logo_f_begin_x = self.surface_w + logo_w
    local logo_f_x = get_easing_value(self.elapsed_time, logo_f_begin_x, end_x - logo_f_begin_x, self.anim_length)
    
    -- Draw each letter.
    self.logo_z:draw(self.surface, logo_z_x, logo_y)
    self.logo_f:draw(self.surface, logo_f_x, logo_y)
  
  elseif self.step == 3 then
    
    -- Clear the surface.
    self.surface:clear()

    local logo_w, logo_h = self.logo_z:get_size()
    local logo_x = (self.surface_w - logo_w) / 2
    local logo_y = (self.surface_h - logo_h) / 2
    
    -- Draw each letter.
    self.logo_z:draw(self.surface, logo_x, logo_y)
    self.logo_f:draw(self.surface, logo_x, logo_y)
    
    -- Draw the triforce.
    self.logo_triforce:draw(self.surface, logo_x, logo_y)
  
  end
end

-- Called when a keyboard key is pressed.
function zeldaforce_logo_menu:on_key_pressed(key)

  if key == "escape" then
    -- Escape: quit Solarus.
    sol.main.exit()
  else
    -- If the timer exists (after step 1).
    if self.timer ~= nil or self.timer2 ~= nil then
      -- Stop the timer.
      if self.timer ~= nil then
        self.timer:stop()
        self.timer = nil
      end
      if self.timer2 ~= nil then
        self.timer2:stop()
        self.timer2 = nil
      end
      if self.step < 3 then
        -- Go directly to last step
        sol.audio.play_sound("sword_spin_attack_load")
        self:step3()
        self:begin_quit(500)

      end

    end

    -- Return true to indicate that the keyboard event was handled.
    return true
  end
end

-- Return the menu to the caller.
return zeldaforce_logo_menu
