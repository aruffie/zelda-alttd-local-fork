local map_meta = sol.main.get_metatable("map")
local hero_meta = sol.main.get_metatable("hero")
require("scripts/multi_events")

local movement=sol.movement.create("straight")
movement:set_speed(88)
movement:set_angle(3*math.pi/2)

function map_meta.set_sideview(sideview)
  map_meta.sideview=sideview
end

function map_meta.is_sideview(sideview)
  return map_meta.sideview or false
end

hero_meta:register_event("on_state_changed", function(self, state)
  print ("STATE CHANGED:"..state)
  local map = self:get_map()
  if map.is_sideview and map:is_sideview() then
    if state == "free"  then
      print "PULL ME DOWN"
      movement:start(self)
    end
  end
end)