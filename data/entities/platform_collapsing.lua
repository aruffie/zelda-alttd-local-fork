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
local max_speed = 22
local solidified=true
local old_x, old_y

local needs_carrying
-- Include scripts
require("scripts/multi_events")

-- Event called when the custom entity is initialized.
entity:register_event("on_created", function()

    sprite = entity:get_sprite()
    entity:set_traversable_by(false)

    --Set whether the hero needs to be carrying a to make the entity move when stepping on it
    needs_carrying = entity:get_property("needs_carrying") 
    if needs_carrying == nil then
      needs_carrying = false
    end

    --Create the vertical movement, but do not alloy to move yet
    movement = sol.movement.create("straight")
    movement:set_speed(0)
    movement:set_angle(3*math.pi/2)
    movement:set_max_distance(0)
    movement:start(entity)
    old_x, old_y=entity:get_position()
  end)

sol.timer.start(entity, 10, function()
    local x, y, w, h = entity:get_bounding_box()
    local ex, ey=entity:get_position()
    local dx, dy = ex-old_x, ey-old_y

    local found=false
    for other in entity:get_map():get_entities("hero") do 

      local xx, yy = other:get_position()
      local hx, hy, hw, hh = other:get_bounding_box()
      if hx+hw<=x+w and hx>=x and hy<=y+h-1 and hy+hh>=y-1 then
        found=true 
      end

      if hy+hh <= y+1 then
        if solidified == true then
--              print "ME SOLID NOW"
          solidified = false
          entity:set_traversable_by("hero", false)
          if hx+hw<=x+w and hx>=x and hy<=y+h-1 and hy+hh>=y-1 then
            other:set_position(xx+dx, yy+dy)
          end
        end


      else
        if solidified == false then
--              print "ME NON SOLID NOW"
          solidified = true
          entity:set_traversable_by("hero", true)
        end
      end
    end

    if found then

      local speed=0
      local anim="moving"
      local state = hero:get_state()

      if needs_carrying=="false" or (needs_carrying=="true" and hero:get_state() == "carrying") then
        speed=max_speed
      end

      --Display the angry visage (or whathever is used to mark the carriable requirement
      if needs_carrying=="true" then
        anim="moving_pot"
      end

      sprite:set_animation(anim)

      --Update the moving speed
      if speed ~= movement:get_speed() then
        movement:set_speed(speed)
      end
    else
      movement:set_speed(0)
      sprite:set_animation("moving")
    end
    old_x, old_y=entity:get_position()
    return true
  end)

--entity:add_collision_test(

--  function(entity, other) --test
--    local x, y, w, h = entity:get_bounding_box()
--    local hx, hy, hw, hh = other:get_bounding_box()
--    return other:get_type() == "hero" and hx+hw<=x+w and hx>=x and hy<=y+h-1 and hy+hh>=y-1
--  end, 

--  function(entity, other) --callback

--    local speed=0
--    local anim="moving"
--    local state = hero:get_state()

--    if needs_carrying=="false" or (needs_carrying=="true" and hero:get_state() == "carrying") then
--      speed=max_speed
--    end
--    local x, y=entity:get_position()
--    --Display the angry visage (or whathever is used to mark the carriable requirement
--    if needs_carrying=="true" then
--      anim="moving_pot"
--    end
--    local dx, dy = x-old_x, y-old_y
--    local xx, yy = other:get_position()
--    if not other:test_obstacles(0, dy) then
--      other:set_position(xx+dx, yy+dy)
--    end
--    sprite:set_animation(anim)

--    --Update the moving speed
--    if speed ~= movement:get_speed() then
--      movement:set_speed(speed)
--    end
--  end)