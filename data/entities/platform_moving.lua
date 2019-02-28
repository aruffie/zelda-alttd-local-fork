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
local is_semisolid
-- Include scripts
--require("scripts/multi_events")

-- Event called when the custom entity is initialized.
--function entity:on_created()
entity:register_event("on_created", function()
  start_x, start_y = entity:get_position()
  old_x, old_y = entity:get_position()
  entity:set_traversable_by(false)
  direction = entity:get_property("direction")
  if direction == nil then
    direction = 0
  end
  distance = entity:get_property("distance")
  if distance == nil then
    distance= 0
  end
  local semisolid = entity:get_property("is_semisolid")
  if semisolid == nil then
    is_semisolid = false
  elseif semisolid == "true" then
    is_semisolid=true
  else
    is_semisolid=false
  end

  start_time=sol.main.get_elapsed_time()
  angle=(direction)/4*math.pi
  ax = math.cos(angle)*distance/2
  ay = -math.sin(angle)*distance/2
end)

local function move_hero_with_me()
    local x,y=entity:get_bounding_box()
    local dx, dy = x-old_x, y-old_y
    local xx, yy = hero:get_position()
    if not hero:test_obstacles(dx, dy) then
      hero:set_position(xx+dx, yy+dy)
    end
end

local function update_hero_position()
  local x,y,w,h=entity:get_bounding_box()
  local hx, hy, hw ,hh=hero:get_bounding_box()
  if is_semisolid then
    if hy+hh<=y+1 then
      entity:set_traversable_by("hero", false)
      if hx<=x+w and hx+hw>=x and hy+hh==y then
        move_hero_with_me()
      end
    else
      entity:set_traversable_by("hero", true)
    end
  else
    if hx<=x+w and hx+hw>=x and hy<=y+h and hy+hh>=y-1 then
      move_hero_with_me()
    end
  end
  old_x, old_y = x, y
end

function entity:on_update()
  local dt=sol.main.get_elapsed_time()-start_time
  local a=-math.cos(dt/1200)+1
  local new_x = start_x + a*ax
  local new_y = start_y + a*ay
  entity:set_position(new_x,new_y)
  update_hero_position()
end