-- Variables
local entity = ...
local game = entity:get_game()
local hero = game:get_hero()
--local movement
local sprite
local start_x, start_y
local old_x, old_y
local direction, distance
local ax, ay
local angle
-- Include scripts
--require("scripts/multi_events")

-- Event called when the custom entity is initialized.
--function entity:on_created()
entity:register_event("on_created", function()
  start_x, start_y = entity:get_position()
  entity:set_traversable_by(false)
  direction = entity:get_property("direction")
  if direction == nil then
    direction = 0
  end
  distance = entity:get_property("distance")
  if distance == nil then
    distance= 0
  end
  start_time=sol.main.get_elapsed_time()
  angle=(direction)/4*math.pi
  ax = math.cos(angle)*distance/2
  ay = -math.sin(angle)*distance/2
  --print (ax, ay, angle)
end)


function entity:on_update()
  local dt=sol.main.get_elapsed_time()-start_time
  local a=-math.cos(dt/1200)+1
  print (a)
  local new_x = start_x + a*ax
  local new_y = start_y + a*ay
  entity:set_position(new_x,new_y)
 
  --Handle the collision with the hero and synchronize movements
  local x,y,w,h=entity:get_bounding_box()
  --print("PLATFORM XY", x,y)
  local hx, hy, hw ,hh=hero:get_bounding_box()
  --print ("HERO XY", hx, hy)
  --print("HERO WH", hw, hh)

  if hx<=x+w and hx+hw>=x and hy<=y+h and hy+hh>=y-1 then
    --print "TOUCH DOWN"
    local dx, dy = x-old_x, y-old_y
    local xx, yy = hero:get_position()
    if not hero:test_obstacles(dx, dy) then
    hero:set_position(xx+dx, yy+dy)
    end
    --print ("HERO XY", xx+dx, yy+dy)
  end
  old_x, old_y = x, y
end