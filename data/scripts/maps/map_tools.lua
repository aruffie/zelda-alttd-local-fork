local map_tools = {}

local audio_manager = require("scripts/audio_manager")

-- Shake the screen
function map_tools.start_earthquake(shake_config)

  local map = sol.main.get_game():get_map()
  map:start_coroutine(function()
    local camera = map:get_camera()
    local timer_sound = sol.timer.start(map, 0, function()
      audio_manager:play_sound("misc/dungeon_shake")
      return 450
    end)
    timer_sound:set_suspended_with_map(false)
    wait_for(camera.shake, camera, shake_config)
    timer_sound:stop()
  end)
end

-- Start an explosion placed randomly around the entity coordinates and restart it while the entity is enabled
function map_tools.start_chained_explosion_on_entity(entity, max_distance, callback)

  local map = entity:get_map()
  local x, y, layer = entity:get_position()
  math.randomseed(sol.main.get_elapsed_time())
  
  audio_manager:play_sound("explosion")

  local explosion = map:create_explosion(
      {name = "chained_explosion", x = x + math.random(-max_distance, max_distance), y = y + math.random(-max_distance, max_distance), layer = layer})
  if explosion ~= nil then -- Avoid Errors when closing the game while a chained explosion is running
    explosion:register_event("on_removed", function(explosion)
      if entity:is_enabled() then
        map_tools.start_chained_explosion_on_entity(entity, max_distance, callback)
      else
        callback()
      end
    end)
  end
end

return map_tools