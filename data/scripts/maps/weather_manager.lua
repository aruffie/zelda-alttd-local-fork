local weather_manager = {}

  weather_manager.ambientlight = {0,0,0,0}

  weather_manager.get_light = function(map)
    return weather_manager.light
  end

  weather_manager.set_light = function(light)
    if light < 0 then light = 0 elseif light > 16 then light = 16 end
    weather_manager.light = light
  end

  weather_manager.add_light = function( amount)
    local light = weather_manager.light - amount
    if light < 0 then light = 0 elseif light > 16 then light = 16 end
    weather_manager.light = light
  end
  
  weather_manager.set_ambient_light = function(ambientlight)
    if ambientlight == nil or ambientlight == "" then
      weather_manager.ambientlight = {0,0,255,48}
    elseif ambientlight == "day" then
      weather_manager.ambientlight = {0,0,0,0}
    elseif ambientlight == "night" then
      weather_manager.ambientlight = {0,0,255,48}
    end
  end

function weather_manager:launch_rain(map)

    local ambientlight = {0,0,0,0}
    for ent in map:get_entities("settings") do
      local lightlevel = split(split(ent:get_name(), "settings:")[1],"-")[1]
      local ambientlevel = split(split(ent:get_name(), "settings:")[1],"-")[2]
      weather_manager:set_light(tonumber(lightlevel))
      weather_manager:set_ambient_light(ambientlevel)
    end


    local rainsprite1 = sol.sprite.create("entities/effects/rain")
    local rainsprite2 = sol.sprite.create("entities/effects/rain")
    rainsprite2:set_direction(1)

    rainsprite1:set_blend_mode("add")
    rainsprite2:set_blend_mode("add")

    local rainposx = {}
    local rainposy = {}

    for i = 1, 4096 do
      rainposx[i] = math.random(2048)
      rainposy[i] = math.random(2048)
    end

    weather_manager.raintimer = 0
    map.on_draw = function(map, dst_surface)

      local camera_x, camera_y = map:get_camera():get_bounding_box()
      dst_surface:fill_color(ambientlight, 0, 0, 1024, 1024)
      dst_surface:fill_color({0, 0, 0, 150}, 0, 0, 1024, 1024)
      if (math.random(100) == 1) then
        dst_surface:fill_color({255, 255, 255, 128}, 0, 0, 1024, 1024)
       if (math.random(5) == 1) then
          audio_manager:play_sound("thunder")
        end
      end
      if weather_manager.raintimer <= 0 then
        weather_manager.raintimer = 150
        audio_manager:play_sound("water_fill")
      end
      weather_manager.raintimer = weather_manager.raintimer - 1
    
      for i = 1, 1024 do
        map:draw_visual(rainsprite1, rainposx[i] + camera_x / 1.5, rainposy[i] + camera_y / 1.5)
      end

      for i = 1024, 4096 do
        map:draw_visual(rainsprite2, rainposx[i] + camera_x / 1.5, rainposy[i] + camera_y / 1.5)
      end
    end

end

-- Start a rain on a sideview map.
function weather_manager:launch_sideview_rain(map, frequency, layer)

  local drop = sol.sprite.create("entities/effects/sideview_rain")
  local splash = sol.sprite.create("entities/effects/sideview_rain")
  local positions = {}
  drop:set_animation("drop")
  splash:set_animation("splash")

  local function start_drop()
    local camera_x, camera_y, camera_width, camera_height = map:get_camera():get_bounding_box()
    table.insert(positions, {x = math.random(camera_x, camera_x + camera_width * 1.5), y = camera_y - 16})
  end

  -- Start a drop periodically.
  local game = map:get_game()
  sol.timer.start(game, frequency, function() -- Start timer on game to not stop it during dialogs.
    if map ~= game:get_map() then
      return
    end
    start_drop()
    return true
  end)

  -- Draw and move.
  map:register_event("on_draw", function(map, dst_surface)

    local camera_x, camera_y, camera_width, camera_height = map:get_camera():get_bounding_box()
    for i, position in pairs(positions) do
      if not position.is_stopped then
        map:draw_visual(drop, position.x, position.y)
        position.x = position.x - 2
        position.y = position.y + 4
        if map:get_ground(position.x, position.y, layer) == "wall" then
          position.is_stopped = true
          splash:set_frame(0)
          map:draw_visual(splash, position.x, position.y)
          positions[i] = nil
        elseif position.y > camera_y + camera_height + 16 then
          positions[i] = nil
        end
      end
    end
  end)
end

return weather_manager