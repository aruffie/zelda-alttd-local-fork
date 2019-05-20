--[[
  Generic moving platform, which oscillates back and forth.
  It can be made semi-solid (you can go through while you are under it, and you can walk on it as soon as you are above it)
  To customize it, use the following custom properties :
    direction (0-7): the direction to follow from the starting position. Defaults to 0 (right)
    distance: the mawimum distance in pisels to go from the starting position. Defaults to 0 (no movement)
    cycle_duration: the back-and-forth duration. defaults to 4000 ms
    is_semisolid: Whether it should be semi-solid. Dafaults to false
    
  Note: The way the semi-solidity is handled makes it incompatible with having multiples heroes.
--]]

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
local is_solidified = true
local elapsed_time

-- Include scripts
require("scripts/multi_events")

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
        
    is_semisolid = entity:get_property("is_semisolid") == "true"

    elapsed_time=0
    angle=(direction)/4*math.pi
    ax = math.cos(angle)*distance/2
    ay = -math.sin(angle)*distance/2
  end)

--This function makes the given entity maintain it's relative position to the platform
local function move_entity_with_me(other)

  local x,y=entity:get_bounding_box()
  local dx, dy = x-old_x, y-old_y
  local xx, yy = other:get_position()

  other:set_position(xx+dx, yy+dy)

end


function entity:on_position_changed()

  local x,y,w,h = entity:get_bounding_box()

  for other in map:get_entities_in_rectangle(x-16, y-16, w+32, h+32) do

    if other ~= entity then
      local e_type = other:get_type()
--      print(e_type)
      if e_type == "hero" or e_type == "npc" or e_type == "enemy" or e_type == "pickable" then
        
        --Update entity position start
        local other_x, other_y, other_w , other_h = other:get_bounding_box()
        
        if is_semisolid then
          if other_y+other_h <= y+1 then
            if e_type == "hero" and is_solidified == true then
              print "ME SOLID NOW"
              is_solidified = false
              entity:set_traversable_by("hero", false)
            end
            if other_x <= x+w and other_x+other_w >= x and other_y+other_h >= y-1 then
              move_entity_with_me(other)
            end
          else
            if e_type == "hero" and is_solidified == false then
              print "ME NON SOLID NOW"
              is_solidified = true
              entity:set_traversable_by("hero", true)
            end
          end
        else
          if other_x<=x+w and other_x+other_w>=x and other_y<=y+h and other_y+other_h>=y-1 then
            move_entity_with_me(other)
          end
        end

        --update entity position end
        
      end
    end
  end
  old_x, old_y = x, y
-- print ("Job's done for" ..(entity:get_name() or "<some entity>")) 
end

function entity:on_update()
  elapsed_time=elapsed_time+10
  local a=-math.cos(elapsed_time/duration*math.pi*2)+1
  local new_x = start_x + a*ax
  local new_y = start_y + a*ay
  entity:set_position(new_x,new_y)
end