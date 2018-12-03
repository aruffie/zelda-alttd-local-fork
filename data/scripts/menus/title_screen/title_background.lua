-- Animated background for the title screen and the file selection menu.
-- Author: Olivier Cléro (oclero@hotmail.com)

local title_background = {}

-- Called when this menu is started.
function title_background:on_started()

  -- This menu is build for a 320x256 pixels size.
  title_background.surface_w = 320
  title_background.surface_h = 256
  title_background.surface = sol.surface.create(title_background.surface_w, title_background.surface_h)
  title_background.sky = sol.surface.create("menus/title_screen/sky.png")
  title_background.background_mountain = sol.surface.create("menus/title_screen/background_mountain.png")
  title_background.background_trees = sol.surface.create("menus/title_screen/background_trees.png")
  title_background.background_beach = sol.surface.create("menus/title_screen/background_beach.png")
  
  -- Dark surface to make a fade out effect.
  title_background.dark_surface = sol.surface.create(title_background.surface_w, title_background.surface_h)
  title_background.dark_surface:fill_color({0, 0, 0})
  title_background.dark_surface:set_opacity(255)

  -- We don't use a map but rather place manually sprites on the background
  -- and move them manually. The reason is to make this cutscene usable as a
  -- simple menu anywhere and anyhow.
  title_background.clouds = sol.sprite.create("menus/title_screen/clouds")
  title_background.mountain_clouds = sol.sprite.create("menus/title_screen/mountain_clouds")
  title_background.wreck = sol.sprite.create("menus/title_screen/wreck")
  title_background.floating_wood = sol.sprite.create("menus/title_screen/floating_wood")
  title_background.wave_big = sol.sprite.create("menus/title_screen/wave_big")
  title_background.wave_small = sol.sprite.create("menus/title_screen/wave_small")
  title_background.swell = sol.sprite.create("menus/title_screen/swell")
  title_background.clouds_top = sol.surface.create(title_background.surface_w, 64 + title_background.surface_h)
  title_background.clouds_top:fill_color({223, 243, 255})

  -- Configure static seagulls.
  title_background.seagull_1 = sol.sprite.create("npc/seagull")
  title_background.seagull_1:set_animation("stopped")
  title_background.seagull_1:set_direction(0)
    
  title_background.seagull_2 = sol.sprite.create("npc/seagull")
  title_background.seagull_2:set_animation("stopped")
  title_background.seagull_2:set_direction(2)

  -- Configure moving seagulls.
  title_background.moving_seagulls = {
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
  title_background.moving_seagulls_started = false

  -- Modified automatically by this script.
  title_background.elapsed_time = 0 
  title_background.y_offset = -256
  title_background.y_begin = -256
  title_background.y_end = -256
  title_background.total_duration = 800

  -- Preload sounds.
  sol.audio.preload_sounds()
 
  -- Phases.
  title_background.PHASE_1, title_background.PHASE_2, title_background.PHASE_3, title_background.PHASE_4, title_background.PHASE_5, title_background.PHASE_6 = 1, 2, 3, 4, 5, 6

  -- Launch animation.
  title_background:set_phase(title_background.PHASE_1)

end

-- Start the camera animation.
function title_background:launch_animation(callback)

  -- Interval between 2 redraw.
  local anim_delta = 1000 / 60 -- ms

  -- Restart the animation.
  title_background.elapsed_time = 0
  if title_background.timer ~= nil then
    title_background.timer:stop()
    title_background.timer = nil
  end

  -- We use a timer called each anim_delta milliseconds.
  -- The timer is called in a loop while the total duration
  -- is below the defined final duration.
  title_background.timer = sol.timer.start(title_background, anim_delta, function()
    -- Elapsed time since launch of animation.
    title_background.elapsed_time = title_background.elapsed_time + anim_delta
    if title_background.elapsed_time < title_background.total_duration then
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
  title_background.surface:clear()

  -- Background.
  local y_offset = math.floor(title_background:get_y_offset(title_background.elapsed_time))
  title_background.y_offset = y_offset
  title_background.sky:draw(title_background.surface, 0, 0)
  local mountain_parallax_factor = 1.3
  local trees_parallax_factor = 1.1
  title_background.background_mountain:draw(title_background.surface, 0, 104 + y_offset * mountain_parallax_factor)
  title_background.background_trees:draw(title_background.surface, 0, 332 + y_offset * trees_parallax_factor)
  title_background.background_beach:draw(title_background.surface, 0, 354 + y_offset)

  -- Moving seagulls (background).
  if title_background.phase >= title_background.PHASE_2 then
    for _, item in pairs(title_background.moving_seagulls) do
      if item.sprite ~= nil and item.type == "background" then
        item.sprite:draw(title_background.surface)
      end
    end
  end

  -- Sprites are placed manually since this is not a map.
  title_background.clouds_top:draw(title_background.surface, 0, -(64 + title_background.surface_h) + y_offset)
  title_background.clouds:draw(title_background.surface, 0, 0 + y_offset)
  title_background.mountain_clouds:draw(title_background.surface, 30, 104 + y_offset * mountain_parallax_factor)
  title_background.wreck:draw(title_background.surface, 152, 452 + y_offset)
  title_background.floating_wood:draw(title_background.surface, 208, 488 + y_offset)
  title_background.floating_wood:draw(title_background.surface, 280, 464 + y_offset)
  for i = 1, 10 do
    title_background.swell:draw(title_background.surface, (i - 1) * 32, 440 + y_offset)
  end
  title_background.wave_big:draw(title_background.surface, 72, 464 + y_offset)
  title_background.wave_big:draw(title_background.surface, 224, 464 + y_offset)
  title_background.wave_big:draw(title_background.surface, 120, 488 + y_offset)
  title_background.wave_big:draw(title_background.surface, 300, 488 + y_offset)
  title_background.wave_big:draw(title_background.surface, 10, 476 + y_offset)
  title_background.wave_small:draw(title_background.surface, 128, 460 + y_offset)
  title_background.wave_small:draw(title_background.surface, 256, 484 + y_offset)

  -- Static seagulls.
  title_background.seagull_1:draw(title_background.surface, 32, 412 + y_offset)
  title_background.seagull_2:draw(title_background.surface, 182, 424 + y_offset)
  
  -- Moving seagulls (foreground).
  if title_background.phase >= title_background.PHASE_2 then
    for _, item in pairs(title_background.moving_seagulls) do
      if item.sprite ~= nil and item.type == "foreground" then
        item.sprite:draw(title_background.surface)
      end
    end
  end

  -- Draw surface on destination.
  title_background.surface:draw(dst_surface, (width - title_background.surface_w)/ 2, (height - title_background.surface_h) / 2)

  -- Dark surface.
  title_background.dark_surface:draw(dst_surface, (width - title_background.surface_w)/ 2, (height - title_background.surface_h) / 2)
end

-- We move the camera with a non-linear movement. Since it is not available
-- in Solarus at the time this script was written, the camera movement is
-- made manually, based on a easing function. 
function title_background:get_y_offset(t)

  local delta = title_background.y_end - title_background.y_begin
  if delta == 0 then
    return title_background.y_end
  else
    t = t / title_background.total_duration * 2
    if t < 1 then
      return delta / 2 * math.pow(t, 2) + title_background.y_begin
    else
      return -delta / 2 * ((t - 1) * (t - 3) - 1) + title_background.y_begin
    end
  end
end

-- Change the phase of the cutscene.
-- Possible phases (in order):
-- 1. "begin"
-- 2. "moving"
-- 3. "end"
function title_background:set_phase(phase)

  if title_background.timer ~= nil then
    title_background.timer:stop()
  end

  -- Phase 1: wait a bit before launching a vertical scroll.
  if phase == title_background.PHASE_1 then
    title_background.phase = phase
    title_background.elapsed_time = 0
    title_background.dark_surface:fade_out(20)

    -- Animation parameters.
    title_background.y_begin = -256
    title_background.y_end = -256
    title_background.y_offset = title_background.y_begin
    title_background.total_duration = 1000

    -- Launch animation phase.
    title_background:launch_animation(function()
      -- Go to next phase.
      title_background:set_phase(title_background.phase + 1)
    end)
  
  -- Phase 2: scroll to the top of the mountain.
  elseif phase == title_background.PHASE_2 then
    title_background.phase = phase
    title_background.elapsed_time = 0

    -- Animation parameters.
    title_background.y_begin = -256
    title_background.y_end = 0
    title_background.y_offset = title_background.y_begin
    title_background.total_duration = 4000

    -- Launch animation phase.
    title_background:launch_animation(function()
      -- Go to next phase.
      title_background:set_phase(title_background.phase + 1)
    end)
    
    -- Start seagulls movements.
    title_background:start_seagulls()

  -- Phase 3: Stop at the top of the mountain. 
  elseif phase == title_background.PHASE_3 then
    title_background.phase = phase
    title_background.elapsed_time = 0
    
    -- Animation parameters.
    title_background.y_begin = 0
    title_background.y_end = 0
    title_background.total_duration = -1

    -- Start seagulls movements, if not done yet.
    title_background:start_seagulls()

  -- Phase 4: scroll down a bit to let the egg appear.
  elseif phase == title_background.PHASE_4 then
    title_background.phase = phase
    title_background.elapsed_time = 0

    -- Animation parameters.
    title_background.y_begin = title_background.y_offset
    title_background.y_end = 64
    title_background.total_duration = 1500

    -- Start seagulls movements, if not done yet.
    title_background:start_seagulls()
    
    -- Launch animation phase.
    title_background:launch_animation(function()
      -- Go to next phase.
      title_background:set_phase(title_background.phase + 1)
    end)

  -- Phase 5: Stop after the scroll
  elseif phase == title_background.PHASE_5 then
    title_background.phase = phase
    title_background.elapsed_time = 0

    -- Start seagulls movements, if not done yet.
    title_background:start_seagulls()
     
    -- Animation parameters.
    title_background.y_begin = 64
    title_background.y_end = 64
    title_background.total_duration = -1

  -- Phase 6: Fade to black.
  elseif phase == title_background.PHASE_6 then
    title_background.phase = phase
    title_background.elapsed_time = 0
 
    -- Animation parameters.
    title_background.y_begin = title_background.y_offset
    title_background.y_end = 256
    title_background.total_duration = 2000

    -- Fade the surface.
    title_background.dark_surface:fade_in(20)
    
    title_background:launch_animation(function()
      -- Stop this menu.
      sol.menu.stop(title_background)
    end)
  end

end

-- Called when this menu is finished.
function title_background:on_finished()
  -- Stop all timers.
  title_background:stop_all_timers()
end

-- Start the seagulls movements.
function title_background:start_seagulls()
  if not title_background.moving_seagulls_started then
    title_background.moving_seagulls_started = true

    for _, seagull in pairs(title_background.moving_seagulls) do
      if seagull.timer ~= nil then
        seagull.timer:stop()
        seagull.timer = nil
      end
      seagull.timer = sol.timer.start(title_background, seagull.start_delay, function()
        title_background:move_seagull(seagull)
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
      seagull.sprite:set_xy(title_background.surface_w + w, seagull.y_begin)
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
  if x >= title_background.surface_w then
    -- The seagull is on the right side.
    seagull.sprite:set_xy(title_background.surface_w + w, seagull.y_begin)
    seagull.sprite:set_direction(2)
    seagull.movement:set_target(-w, seagull.y_end)
  elseif x <= 0 then
    -- The seagull is on the left side.
    seagull.sprite:set_xy(-w, seagull.y_begin)
    seagull.sprite:set_direction(0)
    seagull.movement:set_target(title_background.surface_w + w, seagull.y_end)
  end

  -- Start the movement.
  if sol.menu.is_started(title_background) then
    seagull.movement:start(seagull.sprite, function()
      if seagull.timer ~= nil then
        seagull.timer:stop()
        seagull.timer = nil
      end
      -- When the movement is done, wait a bit, then restart in the opposite direction.
      if sol.menu.is_started(title_background) then
        seagull.timer = sol.timer.start(title_background, 2000, function()
          title_background:move_seagull(seagull)
        end)
      end
    end)
  end
end

-- Security measure: stop all timers.
function title_background:stop_all_timers()
  if title_background.timer ~= nil then
    title_background.timer:stop()
    title_background.timer = nil
  end
  for _, seagull in pairs(title_background.moving_seagulls) do
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
