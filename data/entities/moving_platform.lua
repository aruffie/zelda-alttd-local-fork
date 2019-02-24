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
local is_semitransparent
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
  is_semitransparent = entity:get_property("is_semitransparent")
  if is_semitransparent == nil then
    is_semitransparent = false
  end
  start_time=sol.main.get_elapsed_time()
  angle=(direction)/4*math.pi
  ax = math.cos(angle)*distance/2
  ay = -math.sin(angle)*distance/2
  --print (ax, ay, angle)
end)
local function move_hero_with_me()
    local x,y=entity:get_bounding_box()
    local dx, dy = x-old_x, y-old_y
    local xx, yy = hero:get_position()
    if not hero:test_obstacles(dx, dy) then
    hero:set_position(xx+dx, yy+dy)
    end
end

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

  if is_semitransparent then
    if hy+hh<y+1 then
      entity:set_traversable_by("hero", false)
      print("YOU SHALL NOT PASS !")
      if hx<=x+w and hx+hw>=x and hy+hh==y then
      --print "TOUCH DOWN"
      move_hero_with_me()
      --print ("HERO XY", xx+dx, yy+dy)
      
      end
    else
      entity:set_traversable_by("hero", true)
      print("THIS PLATFORM DOESN'T EXIST")
    end
  else
    if hx<=x+w and hx+hw>=x and hy<=y+h and hy+hh>=y-1 then
      --print "TOUCH DOWN"
      move_hero_with_me()
      --print ("HERO XY", xx+dx, yy+dy)
    end
  end
  old_x, old_y = x, y
end