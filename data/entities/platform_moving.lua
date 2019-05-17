-- Variables
local entity = ...
local game = entity:get_game()
local hero = game:get_hero()
local map = entity:get_map()
--local movement
local sprite
local start_x, start_y
local old_x, old_y
local direction, distance, duration
local ax, ay
local angle
local is_semisolid
local elapsed_time
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
    duration = entity:get_property("cycle_duration")
    if duration == nil then
      duration= 4000
    end
    local semisolid = entity:get_property("is_semisolid")
    if semisolid == nil then
      is_semisolid = false
    elseif semisolid == "true" then
      is_semisolid=true
    else
      is_semisolid=false
    end

    elapsed_time=0
    angle=(direction)/4*math.pi
    ax = math.cos(angle)*distance/2
    ay = -math.sin(angle)*distance/2
  end)

local function move_entity_with_me(other)
  local x,y=entity:get_bounding_box()
  local dx, dy = x-old_x, y-old_y
  local xx, yy = other:get_position()

  other:set_position(xx+dx, yy+dy)

end

local function update_entity_position(other)
  local x,y,w,h=entity:get_bounding_box()
  local xx, yy, ww ,hh = other:get_bounding_box()
  if is_semisolid then
    if yy+hh<=y+1 then
      entity:set_traversable_by("hero", false)
      if xx<=x+w and xx+ww>=x and (yy+hh>=y-1 and yy+hh <= y+1) then
        move_entity_with_me(other)
      end
    else
      entity:set_traversable_by("hero", true)
    end
  else
    if xx<=x+w and xx+ww>=x and yy<=y+h and yy+hh>=y-1 then
      move_entity_with_me(other)
    end
  end
  old_x, old_y = x, y
end

function entity:on_position_changed()

  local x,y,w,h = entity:get_bounding_box()
--  local i=0

  for e in map:get_entities_in_rectangle(x-16, y-16, w+32, h+32) do

    if e ~= entity then
      local e_type = e:get_type()
--      print(e_type)
      if e_type == "hero" or e_type == "npc" or e_type == "enemy" or e_type == "pickable" then
        update_entity_position(e)
      end
    end
--    i=i+1
  end
  print ("Job's done for" ..(entity:get_name() or "<some entity>")) 
  -- print ("# of entities found by "..(entity:get_name() or "<some entity>")..": "..i) 
end

function entity:on_update()
  elapsed_time=elapsed_time+10
  local a=-math.cos(elapsed_time/duration*math.pi*2)+1
  local new_x = start_x + a*ax
  local new_y = start_y + a*ay
  entity:set_position(new_x,new_y)
end