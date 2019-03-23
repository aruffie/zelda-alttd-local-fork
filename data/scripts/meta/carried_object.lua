local carried_meta = sol.main.get_metatable("carried_object")

local m = sol.movement.create("straight")

local old_on_thrown=carried_meta.on_thrown
function carried_meta:on_thrown()
  local map = self:get_map() 
  local hero = map:get_hero()
  if map:is_sideview() then --Make me follow gravity
    m:set_angle(hero:get_sprite():get_direction()*math.pi/2)
    m:set_speed(80)
    m:start(self)
  else --Call regular behavior
    if old_on_thrown ~= nil then
      old_on_thrown(self)
    end
  end
end

local old_on_update=carried_meta.on_update
function carried_meta:on_update()
  local map = self:get_map() 
  local hero = map:get_hero()
  if map:is_sideview() and hero:get_state()~="carrying" and hero:get_state()~="lifting"  then
    --Make me follow gravity 
    local x,y = self:get_position()
    self:set_position(x,y+1)
  else --Call regular behavior
    old_on_update(self)
  end
end