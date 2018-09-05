local lib={}

--[[
Draws a distorsion effect similar to the Ocarina's Mambo's warp song from Zelda: Link's Awakening
Parameters:
  -surface : the surface the effect is applied on
  -game : the Game object, used for the timer
  -mode : the drawing mode of the effect, cen be either:
      in: do the fade-in part
      out: do the fade-out part
  -sfx : the sound effect to play during the effect
  -callback: the function to play once the effect has completed
--]]

function lib.start_effect(surface, game, mode, sfx, callback)
  local min_magnitude=0.01
  local max_magnitude=0.1
  local duration=2.00 --duration of the effect in seconds
  local start_time=os.clock()
  local shader_ocarina = sol.shader.create("distorsion")
  local function lerp(a,b,p)
    return a+p*(b-a)
  end
  if sfx then
    sol.audio.play_sound(sfx)
  end
  surface:set_shader(shader_ocarina)
  sol.timer.start(game, 10, function()
    local current_time=os.clock()-start_time      
    if mode == "in"  or mode == "out" then
      if mode == "in" then --we are fading in
        warp_magnitude = lerp(min_magnitude, max_magnitude, current_time/duration)
        if warp_magnitude > max_magnitude then
          warp_magnitude = max_magnitude
          if callback then
            callback()
          end
          return false
        end
      else --we are fding out
        warp_magnitude = lerp (max_magnitude, min_magnitude, current_time/duration)
        if warp_magnitude < min_magnitude then
          warp_magnitude = min_magnitude
          mode="finished"
        end
      end
      shader_ocarina:set_uniform("magnitude", warp_magnitude)
    elseif mode == "finished" then --the full warp effect is over
      surface:set_shader(nil)
      if callback then
        callback()
      end
      return false
    end
    return true
  end)
end

return lib