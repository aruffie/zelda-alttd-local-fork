local map_meta=sol.main.get_metatable("map")
require("scripts/multi_events")
map_meta:register_event("on_started", function(map)
      map.blocks_remaining={}
end)