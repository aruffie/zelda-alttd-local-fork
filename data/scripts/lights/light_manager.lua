local light_mgr = {occluders={},lights={}}

light_mgr.light_acc = sol.surface.create(sol.video.get_quest_size())
light_mgr.light_acc:set_blend_mode('multiply')

light_mgr.map_occ = sol.surface.create(sol.video.get_quest_size())

function light_mgr:add_occluder(occ,sprite)
  self.occluders[occ]=sprite or occ:get_sprite()
end

function light_mgr:add_light(light,name)
  self.lights[name or light] = light
end

local blocking_grounds = {
  wall = true
}

function light_mgr:bake_map_occluder(map)
  local cx,cy = map:get_camera():get_position()
  local _,_,l = map:get_hero():get_position() -- TODO : use light layer instead
  local dx,dy = cx % 8, cy % 8
  local w,h = self.map_occ:get_size()
  local color = {0,0,0,255}
  self.map_occ:clear()
  for x=0,w,8 do
    for y=0,h,8 do
      local ground = map:get_ground(cx+x,cy+y,l)
      if blocking_grounds[ground] then
        self.map_occ:fill_color(color,x-dx,y-dy,8,8)
      end
    end
  end
  self.occluders[map:get_camera()] = self.map_occ
end

function light_mgr:draw(dst,map)
  self:bake_map_occluder(map)
  self.light_acc:fill_color({0,0,0,255})
  for n,l in pairs(self.lights) do
    l:draw_light(self.light_acc,self.occluders)
  end
  self.light_acc:draw(dst,0,0)
  --self.map_occ:draw(dst,0,0)
end

return light_mgr
