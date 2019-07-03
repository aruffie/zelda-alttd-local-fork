--[[

  Collapsing platform
  
  The name of this entity may be misleading, since it won't abrupltly fall to the ground.
  Actually, when youstep on it, it will slowly go down until eigher step out or it reaches the ground.
  Also you can require the hero to carry something to activate
  
  Custom property:
    needs_carrying: Whether you need to be carrying something to activate platform (defaults to false)

--]]

-- Variables
local entity = ...
local game = entity:get_game()
local hero = game:get_hero()
local sprite
local movement
local new_x, new_y
local old_x, old_y
local min_speed, max_speed = 0, 22

local needs_carrying
local w, h
-- Include scripts
require("scripts/multi_events")

-- Event called when the custom entity is initialized.
entity:register_event("on_created", function()

    sprite = entity:get_sprite()
    w, h = entity:get_size()
    old_x, old_y=entity:get_bounding_box()

    entity:set_traversable_by(false)
    
    --Set whether the hero needs to be carrying a to make the entity move when stepping on it
    needs_carrying = entity:get_property("needs_carrying") 
    if needs_carrying == nil then
      needs_carrying = false
    end
    
    --Create the vertical movement, but do not alloy to move yet
    movement = sol.movement.create("straight")
    movement:set_speed(min_speed)
    movement:set_angle(3*math.pi/2)
    movement:set_max_distance(0)
    movement:start(entity, function()
        print "DONE"
      end)

  end)


function entity:on_update()
  local speed=min_speed
  local anim="moving"
  local state = hero:get_state()
  local x,y=entity:get_bounding_box()
  local hx, hy, hw, hh=hero:get_bounding_box()
  
  --Check whether we are on the platform
  if hx+hw<=x+w and hx>=x and hy<=y+h-1 and hy+hh>=y-1 then
    if needs_carrying=="false" or (needs_carrying=="true" and hero:get_state() == "carrying") then
      speed=max_speed
    end
    
    --Display the angry visage (or whathever is used to mark the carriable requirement
    if needs_carrying=="true" then
      anim="moving_pot"
    end
  end
  
  sprite:set_animation(anim)
  
  --Update the moving speed
  if speed ~= movement:get_speed() then
    movement:set_speed(speed)
  end
  
  --Move the hero with me
  local dx, dy = x-old_x, y-old_y
  local xx, yy = hero:get_position()
  if not hero:test_obstacles(0, dy) then
    hero:set_position(xx+dx, yy+dy)
  end
  
  old_x, old_y = entity:get_bounding_box()
end