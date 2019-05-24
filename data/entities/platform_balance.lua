--[[

  Twin platforms
  
  When one goes up, the other one goes down.
  And what's even cooler is that it manages it's own chain. No extra entity required!
  
  To make the system work:
  
  1. place two custom entities on the map. Any size will work
  2. Apply this model to them, as well as a sprite so you can see them
  3. Give them a name accoring to these rules:
    -They must have the same prefix, which will be unique for this particular couple
    -It must finish the caracter "_", following by either 1 or 2
  If configures correctly, then their movements shound be mirrored when stepped on
  
--]]

-- Variables
local entity = ...

local game = entity:get_game()
local hero = game:get_hero()
local max_dy=1
local accel = 0.1
local accel_duration = 1
entity.direction = 0
local old_x=0
local old_y=0
local true_x, true_y
local speed=0
local w, h
local twin=nil
local chain=nil

-- Include scripts
--require("scripts/multi_events")

-- Event called when the custom entity is initialized.
entity:register_event("on_created", function()
    --Get the twin entity
    local name=entity:get_name()
    twin = entity:get_map():get_entity(name:sub(1, -3).."_"..(3-tonumber(name:sub(-1)))) 

    --Set me up
    w, h = entity:get_size()
    old_x, old_y=entity:get_bounding_box()
    entity:set_traversable_by(false)
    entity.is_on_twin=false
    local true_layer
    true_x, true_y = entity:get_position()

    --Create it's chain
    chain = entity:get_map():create_custom_entity({
        x=true_x,
        y=true_y%16,
        layer=entity:get_layer(),
        direction = 0,
        width=16,
        height =true_y-(true_y%16),
        sprite = "entities/moving_platform_dg_5_chain", 
      })
    chain:set_tiled(true)
    chain:set_origin(8, 13)
  end)

--Utility function, self-explanatory
local function is_on_platform(e) 
  local x,y=e:get_bounding_box()
  local hx, hy, hw, hh=hero:get_bounding_box()
  return hx<x+w and hx+hw>x and hy<=y+h-1 and hy+hh>=y-1
end


function entity:on_removed()
  if chain then
    chain:remove()
  end
end

function entity:on_disbled()
  if chain then
    chain:set_enabled(false)
  end    
end

function entity:on_enabled()
  if chain then
    chain:set_enabled(true)
  end    
end

function entity:on_update()
  local x,y=entity:get_bounding_box()
  local hx, hy, hw, hh=hero:get_bounding_box()
  if is_on_platform(entity) then
    --print("we are on "..entity:get_name())

    speed = math.min(speed+0.01*max_dy, max_dy)
  elseif is_on_platform(twin) then
    speed = math.max(speed-0.01*max_dy, -max_dy)
  else
    if speed >0 then
      speed = math.max(speed-0.01*max_dy, 0)
    else
      speed = math.min(speed+0.01*max_dy, 0)
    end
  end

  --Compute the new position
  if entity:test_obstacles(0, speed)==false and twin:test_obstacles(0, -speed)==false then
    --Only move if any of the platforms can move
    true_y=true_y+speed
    entity:set_position(true_x, true_y)
  else
    speed = 0
  end

  --Move the hero with me
  local dx, dy = x-old_x, y-old_y
  local xx, yy = hero:get_position()
  if not hero:test_obstacles(0, dy) and is_on_platform(entity) then
    hero:set_position(xx+dx, yy+dy)
  end

  old_x, old_y = entity:get_bounding_box()
  --local chain = entity:get_map():get_entity(group.."_chain_"..id)
  local dy = old_y+13
  chain:set_position(old_x+8, dy%16) 

  chain:set_size(w, math.max(8, dy-(dy%16)))
end