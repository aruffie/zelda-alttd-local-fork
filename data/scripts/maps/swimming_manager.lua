----------------------------------
--
-- Sideview swimming feature.
--
----------------------------------
local swimming_manager = {}

-- Variables.
local swimming_speed = 66
local is_swimming = false

-- Update the hero while swimming.
local function update_hero()

  if desc == "sword_loading" then

    if hero:get_ground_below() == "deep_water" then
      new_animation = "swimming_scroll_loading"
      hero:get_sprite("sword"):set_animation("sword_loading_swimming_scroll")  
    end
  end

  if state=="free" and not (hero.frozen) then
    if speed ~= 0 then
      if hero.has_grabbed_ladder and check_for_ladder(hero) then
        new_animation = "climbing_walking"
      elseif not is_on_ground(hero) then
        if map:get_ground(x,y+4,layer)=="deep_water" then
          new_animation ="swimming_scroll"
        else
          new_animation = "jumping"
        end
      else
        new_animation = "walking"
      end
    else
      if hero.has_grabbed_ladder and check_for_ladder(hero) then
        new_animation = "climbing_stopped"
      elseif not is_on_ground(hero) then
        if map:get_ground(x,y+4,layer)=="deep_water" then
          new_animation = "stopped_swimming_scroll"
        else
          new_animation = "jumping"
        end
      else
        new_animation = "stopped"
      end 
    end
  end
end

-- Start the hero swim.
local function start_swimming()

end

-- Get swimming speed.
function swimming_manager.get_swimming_speed()
  return swimming_speed
end

-- Check for water below the entity.
function swimming_manager.check_for_water(entity)

  local map = entity:get_map()
  local x,y,layer = entity:get_position() 
  local bx, by, w, h = entity:get_bounding_box()
  local ox, oy = entity:get_origin()

  for i = bx, bx + w - 1, 8 do
    if map:get_ground(i, by + h, layer) ~= "deep_water" then
      return false
    end
  end
  return map:get_ground(bx + w - 1, by + h, layer) =="deep_water"
end

-- Initialize the swimming ability.
function swimming_manager.initialize()

  local hero_meta=sol.main.get_metatable("hero")

  function hero_meta:start_swimming()
    is_swimming = true
  end

  function hero_meta:is_swimming()
    return is_swimming
  end
end

--[[
state:set_can_use_sword(true)
state:set_can_use_item(false)
state:set_can_use_item("feather", true)
state:set_can_use_item("hookshot", true)
state:set_can_control_movement(true)
state:set_can_control_direction(true)



function state:on_position_changed(x,y,layer)
  -- debug_print "i'm swiiiiiiiming in the poool, just swiiiiiming in the pool"
  local entity=state:get_entity()
  local map = state:get_map()
  if map:get_ground(x,y,layer)~="deep_water" then
    entity:unfreeze()
  end
end
]]