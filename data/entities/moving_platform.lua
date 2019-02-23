-- Variables
local entity = ...
local game = entity:get_game()
local hero = game:get_hero()
--local movement
local sprite
local default_x = 64
local default_y = 0
local amplitude_x=default_x
local amplitude_y=default_y
local start_x, start_y
local old_x, old_y
-- Include scripts
--require("scripts/multi_events")

-- Event called when the custom entity is initialized.
--function entity:on_created()
entity:register_event("on_created", function()
  start_x, start_y = entity:get_position()
  entity:set_traversable_by(false)
  amplitude_x = entity:get_property("amplitude_x")
  if amplitude_x == nil then
    amplitude_x = default_x
  end
  amplitude_y = entity:get_property("amplitude_y")
  if amplitude_y == nil then
    amplitude_y = default_y
  end
  start_time=sol.main.get_elapsed_time()
  

end)


function entity:on_update()
  local dt=sol.main.get_elapsed_time()-start_time
  local a=math.sin(dt/2500)
  local new_x = start_x + a*a*amplitude_x
  local new_y = start_y + a*a*amplitude_y
  entity:set_position(new_x,new_y)
 
  --Handle the collision with the hero and synchronize movements
  local x,y,w,h=entity:get_bounding_box()
  print("PLATFORM XY", x,y)
  local hx, hy, hw ,hh=hero:get_bounding_box()
  print ("HERO XY", hx, hy)
  print("HERO WH", hw, hh)

  if hx<=x+w and hx+hw>=x and hy<=y+h and hy+hh>=y-1 then
    print "TOUCH DOWN"
    local dx, dy = x-old_x, y-old_y
    local xx, yy = hero:get_position()
    if not hero:test_obstacles(dx, dy) then
    hero:set_position(xx+dx, yy+dy)
    end
    --print ("HERO XY", xx+dx, yy+dy)
  end
  old_x, old_y = x, y
end