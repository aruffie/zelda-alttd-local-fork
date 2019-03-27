local carried_meta = sol.main.get_metatable("carried_object")
require ("scripts/multi_events")

carried_meta:register_event("on_thrown", function(object)
  local map = object:get_map() 
  local hero = map:get_hero()
  if map:is_sideview() then --Make me follow gravity
    local m = sol.movement.create("straight")
    m:set_angle(hero:get_sprite():get_direction()*math.pi/2)
    m:set_speed(92)
    m:start(object)
  end --Call regular behavior
end)