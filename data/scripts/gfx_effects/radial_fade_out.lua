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
require("scripts/multi_events")
local duration=1500
local max_radius=360

function lib.start_effect(surface, game, mode, sfx, callback)

  local shader=sol.shader.create("radial_fade_out")
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

  surface:set_shader(shader) --Attach the shader to the surface
  local start_time=sol.main.get_elapsed_time()
  sol.timer.start(game, 10, function()
    local player_x, player_y=game:get_hero():get_position()
    local cam_x, cam_y=game:get_map():get_camera():get_position()
    local radius
    local elapsed=sol.main.get_elapsed_time()-start_time
    if mode=="in" then
      radius=lerp(max_radius, 0, elapsed/duration)
      if radius<0 then
        game:get_map():register_event("on_draw", function(map, dst_surface)
          surface:fill_color({0,0,0})
        end)
        surface:set_shader(nil)
        if callback then
          callback()
        end
        return false
      end
    else
      radius=lerp(0, max_radius, elapsed/duration)
      if radius>max_radius then
        surface:set_shader(nil)
        if callback then
          callback()
        end
        return false
      end
    end
    shader:set_uniform("radius", radius)
    shader:set_uniform("position", {player_x-cam_x, player_y-cam_y-13})
    return true
  end) --START DRAWING!
end

return lib