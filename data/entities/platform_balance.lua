-- Variables
local entity = ...

local easings=require "scripts/automation/easing"

local game = entity:get_game()
local hero = game:get_hero()
entity.is_reverse=false
local m
local new_x, new_y
local old_x, old_y
local min_speed, max_speed = 0, 92
local speed
local id, group --will be used to activate it's twin entity
local w, h
-- Include scripts
--require("scripts/multi_events")

-- Event called when the custom entity is initialized.
entity:register_event("on_created", function()
  local name=entity:get_name()
  id = tonumber(name:sub(-1))
  group = name:sub(1, -3)
  sprite = entity:get_sprite()
  w, h = entity:get_size()
  old_x, old_y=entity:get_bounding_box()
  entity:set_traversable_by(false)
  speed = min_speed
  m = sol.movement.create("straight")
  m:set_speed(speed)
  m:set_angle(3*math.pi/2)
  m:set_max_distance(0)
  m:start(entity)
end)

local function move_hero_with_me()
    local x,y=entity:get_bounding_box()
    local dx, dy = x-old_x, y-old_y
    local xx, yy = hero:get_position()
    if not hero:test_obstacles(0, dy) then
      hero:set_position(xx+dx, yy+dy)
    end
end

function entity:on_update()
  local state = hero:get_state()
  local x,y=entity:get_bounding_box()
  local hx, hy, hw, hh=hero:get_bounding_box()
  if hx<x+w and hx+hw>x and hy<=y+h-1 and hy+hh>=y-1 then
    entity:get_map():get_entity(group.."_"..(3-id)).is_reversed=true
    is_on_platform = true
  else
    is_on_platform = false
    entity:get_map():get_entity(group.."_"..(3-id)).is_reversed=false
  end
  if entity.is_reversed then
    m:set_angle(math.pi/2)
  else
    m:set_angle(3*math.pi/2)
  end
  if entity.is_reversed or is_on_platform then
    speed = math.min(speed + 1, max_speed)
  else
    speed = math.max(speed - 1, min_speed)
  end
  m:set_speed(speed)
  move_hero_with_me()
  old_x, old_y = entity:get_bounding_box()
end