local lib={}
--[[
  Starts an electric effect
  Parameters:
    surface : the surface to apply the shader on;
    game : the game object
    sfx : The sound to play during the transition
    callback (optional): the function to execute after the effect is finiched playing
--]]

local duration=2000          --Duration of the effect

function lib.start_effect(surface, game, sfx, callback)

  local shader=sol.shader.create("electric")

  if not surface then
    print("Error : No surface has been passed")
    return
  end
  callback=callback or nil
  if _sfx then
    sol.audio.play_sound(_sfx)
  end
  surface:set_shader(shader) --Attach the shader to the surface
  sol.timer.start(game, duration, function()
    --clear the shader, do the callback and stop the timer loop
    surface:set_shader(nil)
    if callback then
      callback()
    end
  end)

end

return lib