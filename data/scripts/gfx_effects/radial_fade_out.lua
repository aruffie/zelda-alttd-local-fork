local lib={}
--[[
  Starts a circle effect similar to ALTTP transition from/to interiors.
  Parameters:
    surface : the surface to apply the shader on;
    game : the game object
    mode : the drawing mode of the effect, can be either:
      "in": do the fade-in part
      "out": do the fade-out part
    sfx : The sound to play during the effect
    callback (optional): the function to execute after the effect is finiched playing
--]]
local duration=1500
local max_radius=360

function lib.start_effect(surface, game, mode, sfx, callback)

  local shader=sol.shader.create("radial_fade_out")
  local player_x, player_y=game:get_hero():get_position()
  local cam_x, cam_y=game:get_map():get_camera():get_position()
  if not surface then
    print("Error : No surface has been passed")
    return
  end
  if not(mode=="in" or mode=="out") then

    print("Error:unknown drawing mode")
    return
  end
  local function lerp(a,b,p)
    return a+p*(b-a)
  end
  if sfx then
    sol.audio.play_sound(sfx)
  end
  local radius
  surface:set_shader(shader) --Attach the shader to the surface
  local start_time=sol.main.get_elapsed_time()
  sol.timer.start(game, 10, function()
    local elapsed=sol.main.get_elapsed_time()-start_time
    local step
    if mode=="in" then
      radius=lerp(max_radius, 0, elapsed/duration)
    else
      radius=lerp(0, max_radius, elapsed/duration)
    end
    shader:set_uniform("radius", radius)
    shader:set_uniform("position", {player_x-cam_x, player_y-cam_y-13})
    if (mode=="out" and radius>max_radius) or (mode=="in" and radius<=0) then
      --clear the shader, do the callback and stop the timer loop
      surface:set_shader(nil)
      if callback then
        callback()
      end
      return false
    end
    return true
  end) --START DRAWING!
end

return lib