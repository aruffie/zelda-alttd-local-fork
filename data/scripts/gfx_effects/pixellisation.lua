local lib={}
--[[
  Starts a pixellisation effect similar to ALTTP transition from/to the Zora's Domain or Lost Woods.
  Parameters:
    surface : the surface to apply the shader on;
    game : the game object
    mode : how the effect is played, can be either :
      "fade_in": the zooming-in effect only,
      "fade_out": the zooming-out effect only,
      "fade_both": zoom in and out in the same call.
    sfx : The sound to play during the transition
    callback (optional): the function to execute after the effect is finiched playing
--]]

local max_step=7          --Number of drawing steps (the corresponding pixel width is 2^step)
local step_duration=0.15  --Step duration in seconds

function lib.start_effect(surface, game, mode, sfx, callback)

  local shader=sol.shader.create("pixellisation")

  if not surface then
    print("Error : No surface has been passed")
    return
  end
  if not(mode=="in" or mode=="out" or mode=="both") then

    print("Error:unknown drawing mode")
    return
  end
  callback=callback or nil
  if _sfx then
    sol.audio.play_sound(_sfx)
  end
  local is_dezooming=(mode=="out")
  surface:set_shader(shader) --Attach the shader to the surface
  local start_time=os.clock()
  sol.timer.start(game, 10, function()
    local current_time=os.clock()-start_time
    local step
    if mode=="out" or (mode=="both" and is_dezooming==true) then
      step=max_step-(current_time/step_duration)
    else
      step=(current_time/step_duration)
    end
    shader:set_uniform("step", step)
    if (mode=="in" or mode=="both" and is_dezooming==false) and step>=max_step
       or (mode=="out" or mode=="both" and is_dezooming==true) and step<=0 then
      --we are at the end of the current zoom/dezoom
      if mode=="both" and not is_dezooming then
        --if we doing both fade-in and fade_out, and are still on fading in, then switch to fade out
        start_time=os.clock()
        is_dezooming=true
      else
        --clear the shader, do the callback and stop the timer loop
        surface:set_shader(nil)
        if callback then
          callback()
        end
        return false
      end
    end
    return true
  end) --START DRAWING!
end

return lib