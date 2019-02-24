-- Variables
local entity = ...
local game = entity:get_game()
local hero = game:get_hero()
local sprite
local movement
local new_x, new_y
local old_x, old_y
local min_speed, max_speed = 0, 91

local activation_weight
local w, h
-- Include scripts
--require("scripts/multi_events")

-- Event called when the custom entity is initialized.
entity:register_event("on_created", function()

  sprite = entity:get_sprite()
  w, h = entity:get_size()
  old_x, old_y=entity:get_bounding_box()

  entity:set_traversable_by(false)
  activation_weight = tonumber(entity:get_property("activation_weight"))
  if activation_weight == nil then
    activation_weight = 0
  end

  movement = sol.movement.create("straight")
  movement:set_speed(min_speed)
  movement:set_angle(3*math.pi/2)
  movement:set_max_distance(0)
  movement:start(entity, function()
    print "DONE"
  end)
  
end)

local function move_hero_with_me()
    --print "Let's move"
    local x,y=entity:get_bounding_box()
    local dx, dy = x-old_x, y-old_y
    local xx, yy = hero:get_position()
    if not hero:test_obstacles(0, dy) then
      hero:set_position(xx+dx, yy+dy)
    end
end

function entity:on_update()
  local speed=min_speed
  local anim="moving"
  local state = hero:get_state()
  local x,y=entity:get_bounding_box()
  local hx, hy, hw, hh=hero:get_bounding_box()
  if hx+hw<=x+w and hx>=x and hy<=y+h-1 and hy+hh>=y-1 then
    if activation_weight == 0 or (activation_weight==1 and hero:get_state() == "carrying") then
      speed=max_speed
    end
    anim="moving_pot"
  end
  sprite:set_animation(anim)
  movement:set_speed(speed)
  move_hero_with_me()
  old_x, old_y = entity:get_bounding_box()
end