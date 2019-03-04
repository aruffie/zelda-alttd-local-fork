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
local _x, _y
local id=""
local speed=0
local group="" --will be used to activate it's twin entity
local w=16
local h=16
local twin=nil
local chain=nil

-- Include scripts
--require("scripts/multi_events")

-- Event called when the custom entity is initialized.
entity:register_event("on_created", function()
  local name=entity:get_name()
  id = tonumber(name:sub(-1))
  group = name:sub(1, -3)
  w, h = entity:get_size()
  old_x, old_y=entity:get_bounding_box()
  entity:set_traversable_by(false)
  entity.is_on_twin=false
  _x, _y, _layer = entity:get_position()
  twin = entity:get_map():get_entity(group.."_"..(3-id))
  chain = entity:get_map():create_custom_entity({
    x=_x,
    y=_y%16,
    layer=_layer,
    direction = 0,
    width=w,
    height =_y-(_y%16),
    sprite = "entities/moving_platform_dg_5_chain",
    model = "platform_chain", 
  })
  chain:set_tiled(true)
  chain:set_origin(8, 13)
end)

local function is_on_platform(e) 
  local x,y=e:get_bounding_box()
  local hx, hy, hw, hh=hero:get_bounding_box()
  return hx<x+w and hx+hw>x and hy<=y+h-1 and hy+hh>=y-1
end

local function move_hero_with_me()
    local x,y=entity:get_bounding_box()
    local dx, dy = x-old_x, y-old_y
    local xx, yy = hero:get_position()
    if not hero:test_obstacles(0, dy) and is_on_platform(entity) then
      hero:set_position(xx+dx, yy+dy)
    end
end
local function compute_new_xy()
  --print("Entity "..entity:get_name()..": am i  stuck ?"..(entity:test_obstacles(0, 1) and "Yes" or "No"))
  if entity:test_obstacles(0, speed)==false and twin:test_obstacles(0, -speed)==false then
    --Only move if any of the platforms can move
    _y=_y+speed
    entity:set_position(_x, _y)
  else
    speed = 0
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

  compute_new_xy()
  move_hero_with_me()
  old_x, old_y = entity:get_bounding_box()
  --local chain = entity:get_map():get_entity(group.."_chain_"..id)
  local dy = old_y+13
  chain:set_position(old_x+8, dy%16) 
  
  chain:set_size(w, math.max(8, dy-(dy%16)))
end