-- Animated background for the title screen and the file selection menu.
-- Author: Olivier Cléro (oclero@hotmail.com)

local title_background = {}

-- Called when this menu is started.
function title_background:on_started()

  -- This menu is build for a 320x256 pixels size.
  self.surface_w = 320
  self.surface_h = 256
  self.surface = sol.surface.create(self.surface_w, self.surface_h)
  self.sky = sol.surface.create("menus/title_screen/sky.png")
  self.background_mountain = sol.surface.create("menus/title_screen/background_mountain.png")
  self.background_trees = sol.surface.create("menus/title_screen/background_trees.png")
  self.background_beach = sol.surface.create("menus/title_screen/background_beach.png")
  
  -- Dark surface to make a fade out effect.
  self.dark_surface = sol.surface.create(self.surface_w, self.surface_h)
  self.dark_surface:fill_color({0, 0, 0})
  self.dark_surface:set_opacity(255)

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
  self.clouds_top = sol.surface.create(self.surface_w, 64 + self.surface_h)
  self.clouds_top:fill_color({223, 243, 255})

  -- Configure static seagulls.
  self.seagull_1 = sol.sprite.create("npc/seagull")
  self.seagull_1:set_animation("stopped")
  self.seagull_1:set_direction(0)
    
  self.seagull_2 = sol.sprite.create("npc/seagull")
  self.seagull_2:set_animation("stopped")
  self.seagull_2:set_direction(2)

  -- Configure moving seagulls.
  self.moving_seagulls = {
    {
      y_begin = 120,
      y_end = 180,
      begin_side = "left",
      start_delay = 2000,
      speed = 48,
      type = "foreground",
    },
    {
      y_begin = 180,
      y_end = 240,
      begin_side = "right",
      start_delay = 4500,
      speed = 40,
      type = "foreground",
    },
    {
      y_begin = 100,
      y_end = 120,
      begin_side = "right",
      start_delay = 2500,
      speed = 32,
      type = "background",
    },
    {
      y_begin = 140,
      y_end = 100,
      begin_side = "left",
      start_delay = 2700,
      speed = 32,
      type = "background",
    },
    {
      y_begin = 200,
      y_end = 160,
      begin_side = "right",
      start_delay = 3000,
      speed = 32,
      type = "background",
    },
  }
  self.moving_seagulls_started = false

  -- Modified automatically by this script.
  self.elapsed_time = 0 
  self.y_offset = -256
  self.y_begin = -256
  self.y_end = -256
  self.total_duration = 800

  -- Preload sounds.
  sol.audio.preload_sounds()
 
  -- Phases.
  self.PHASE_1, self.PHASE_2, self.PHASE_3, self.PHASE_4, self.PHASE_5, self.PHASE_6 = 1, 2, 3, 4, 5, 6

  -- Launch animation.
  self:set_phase(self.PHASE_1)

end

-- Start the camera animation.
function title_background:launch_animation(callback)

  -- Interval between 2 redraw.
  local anim_delta = 1000 / 60 -- ms

  -- Restart the animation.
  self.elapsed_time = 0
  if self.timer ~= nil then
    self.timer:stop()
    self.timer = nil
  end

  -- We use a timer called each anim_delta milliseconds.
  -- The timer is called in a loop while the total duration
  -- is below the defined final duration.
  self.timer = sol.timer.start(self, anim_delta, function()
    -- Elapsed time since launch of animation.
    self.elapsed_time = self.elapsed_time + anim_delta
    if self.elapsed_time < self.total_duration then
      -- Keep on updating while time is remaining.
      -- Relaunch the timer once again.
      return true
    else
      -- Call the callback at the end of the animation.
      if callback ~= nil then
        callback()
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
  self.y_offset = y_offset
  self.sky:draw(self.surface, 0, 0)
  local mountain_parallax_factor = 1.3
  local trees_parallax_factor = 1.1
  self.background_mountain:draw(self.surface, 0, 104 + y_offset * mountain_parallax_factor)
  self.background_trees:draw(self.surface, 0, 332 + y_offset * trees_parallax_factor)
  self.background_beach:draw(self.surface, 0, 354 + y_offset)

  -- Moving seagulls (background).
  if self.phase >= self.PHASE_2 then
    for _, item in pairs(self.moving_seagulls) do
      if item.sprite ~= nil and item.type == "background" then
        item.sprite:draw(self.surface)
      end
    end
  end

  -- Sprites are placed manually since this is not a map.
  self.clouds_top:draw(self.surface, 0, -(64 + self.surface_h) + y_offset)
  self.clouds:draw(self.surface, 0, 0 + y_offset)
  self.mountain_clouds:draw(self.surface, 30, 104 + y_offset * mountain_parallax_factor)
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

  -- Static seagulls.
  self.seagull_1:draw(self.surface, 32, 412 + y_offset)
  self.seagull_2:draw(self.surface, 182, 424 + y_offset)
  
  -- Moving seagulls (foreground).
  if self.phase >= self.PHASE_2 then
    for _, item in pairs(self.moving_seagulls) do
      if item.sprite ~= nil and item.type == "foreground" then
        item.sprite:draw(self.surface)
      end
    end
  end

  -- Draw surface on destination.
  self.surface:draw(dst_surface, (width - self.surface_w)/ 2, (height - self.surface_h) / 2)

  -- Dark surface.
  self.dark_surface:draw(dst_surface, (width - self.surface_w)/ 2, (height - self.surface_h) / 2)
end

-- We move the camera with a non-linear movement. Since it is not available
-- in Solarus at the time this script was written, the camera movement is
-- made manually, based on a easing function. 
function title_background:get_y_offset(t)

  local delta = self.y_end - self.y_begin
  if delta == 0 then
    return self.y_end
  else
    t = t / self.total_duration * 2
    if t < 1 then
      return delta / 2 * math.pow(t, 2) + self.y_begin
    else
      return -delta / 2 * ((t - 1) * (t - 3) - 1) + self.y_begin
    end
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

  -- Phase 1: wait a bit before launching a vertical scroll.
  if phase == self.PHASE_1 then
    self.phase = phase
    self.elapsed_time = 0
    self.dark_surface:fade_out(20)

    -- Animation parameters.
    self.y_begin = -256
    self.y_end = -256
    self.y_offset = self.y_begin
    self.total_duration = 1000

    -- Launch animation phase.
    self:launch_animation(function()
      -- Go to next phase.
      self:set_phase(self.phase + 1)
    end)
  
  -- Phase 2: scroll to the top of the mountain.
  elseif phase == self.PHASE_2 then
    self.phase = phase
    self.elapsed_time = 0

    -- Animation parameters.
    self.y_begin = -256
    self.y_end = 0
    self.y_offset = self.y_begin
    self.total_duration = 4000

    -- Launch animation phase.
    self:launch_animation(function()
      -- Go to next phase.
      self:set_phase(self.phase + 1)
    end)
    
    -- Start seagulls movements.
    self:start_seagulls()

  -- Phase 3: Stop at the top of the mountain. 
  elseif phase == self.PHASE_3 then
    self.phase = phase
    self.elapsed_time = 0
    
    -- Animation parameters.
    self.y_begin = 0
    self.y_end = 0
    self.total_duration = -1

    -- Start seagulls movements, if not done yet.
    self:start_seagulls()

  -- Phase 4: scroll down a bit to let the egg appear.
  elseif phase == self.PHASE_4 then
    self.phase = phase
    self.elapsed_time = 0

    -- Animation parameters.
    self.y_begin = self.y_offset
    self.y_end = 64
    self.total_duration = 1500

    -- Start seagulls movements, if not done yet.
    self:start_seagulls()
    
    -- Launch animation phase.
    self:launch_animation(function()
      -- Go to next phase.
      self:set_phase(self.phase + 1)
    end)

  -- Phase 5: Stop after the scroll
  elseif phase == self.PHASE_5 then
    self.phase = phase
    self.elapsed_time = 0

    -- Start seagulls movements, if not done yet.
    self:start_seagulls()
     
    -- Animation parameters.
    self.y_begin = 64
    self.y_end = 64
    self.total_duration = -1

  -- Phase 6: Fade to black.
  elseif phase == self.PHASE_6 then
    self.phase = phase
    self.elapsed_time = 0
 
    -- Animation parameters.
    self.y_begin = self.y_offset
    self.y_end = 256
    self.total_duration = 2000

    -- Fade the surface.
    self.dark_surface:fade_in(20)
    
    self:launch_animation(function()
      -- Stop this menu.
      sol.menu.stop(self)
    end)
  end

end

-- Called when this menu is finished.
function title_background:on_finished()
  -- Stop all timers.
  self:stop_all_timers()
end

-- Start the seagulls movements.
function title_background:start_seagulls()
  if not self.moving_seagulls_started then
    self.moving_seagulls_started = true

    for _, seagull in pairs(self.moving_seagulls) do
      if seagull.timer ~= nil then
        seagull.timer:stop()
        seagull.timer = nil
      end
      seagull.timer = sol.timer.start(self, seagull.start_delay, function()
        self:move_seagull(seagull)
      end)
    end
  end
end

-- Move a seagull sprite on the screen.
function title_background:move_seagull(seagull)
  
  if seagull.sprite == nil then
    if seagull.type == "foreground" then 
      seagull.sprite = sol.sprite.create("npc/seagull")
      seagull.sprite:set_animation("walking")  
    else
      seagull.sprite = sol.sprite.create("npc/seagull_small")
      seagull.sprite:set_animation("default")
    end

    local w, h = seagull.sprite:get_size()
    if seagull.begin_side == "left" then
      seagull.sprite:set_xy(-w, seagull.y_begin)
    else
      seagull.sprite:set_xy(self.surface_w + w, seagull.y_begin)
    end
  end

  if seagull.movement == nil then
    seagull.movement = sol.movement.create("target")
    seagull.movement:set_speed(seagull.speed)
    seagull.movement:set_ignore_obstacles(true)
    seagull.movement:set_smooth(true)
  end

  local x, y = seagull.sprite:get_xy()
  local w, h = seagull.sprite:get_size()
  if x >= self.surface_w then
    -- The seagull is on the right side.
    seagull.sprite:set_xy(self.surface_w + w, seagull.y_begin)
    seagull.sprite:set_direction(2)
    seagull.movement:set_target(-w, seagull.y_end)
  elseif x <= 0 then
    -- The seagull is on the left side.
    seagull.sprite:set_xy(-w, seagull.y_begin)
    seagull.sprite:set_direction(0)
    seagull.movement:set_target(self.surface_w + w, seagull.y_end)
  end

  -- Start the movement.
  if sol.menu.is_started(self) then
    seagull.movement:start(seagull.sprite, function()
      if seagull.timer ~= nil then
        seagull.timer:stop()
        seagull.timer = nil
      end
      -- When the movement is done, wait a bit, then restart in the opposite direction.
      if sol.menu.is_started(self) then
        seagull.timer = sol.timer.start(self, 2000, function()
          self:move_seagull(seagull)
        end)
      end
    end)
  end
end

-- Security measure: stop all timers.
function title_background:stop_all_timers()
  if self.timer ~= nil then
    self.timer:stop()
    self.timer = nil
  end
  for _, seagull in pairs(self.moving_seagulls) do
    if seagull.timer ~= nil then
      seagull.timer:stop()
      seagull.timer = nil
    end
    if seagull.movement ~= nil then
      seagull.movement:stop()
      seagull.movement = nil
    end
  end
end

-- The cutscene is just a background, and does not use any keyboard event.
function title_background:on_key_pressed(key)
  return false
end

return title_background
