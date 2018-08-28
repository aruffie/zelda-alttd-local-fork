local companion_manager = {}
local map_meta = sol.main.get_metatable("map")
map_meta.companion_allowed = true 
require("scripts/multi_events")

function companion_manager:init(map)

  local game = map:get_game()
  function game:on_map_changed() 
    -- Todo
  end

  
end

-- Get companion status
function map_meta:get_companion_allowed(status)

  return map_meta.companion_allowed

end

-- Enable/disabled companion

function map_meta:set_companion_allowed()

  map_meta.companion_allowed = status 

end

