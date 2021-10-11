----------------------------------
--
-- Sideview swimming feature.
--
----------------------------------
local swimming_manager = {}

-- Global variables.
local is_swimming = false

-- Configuration variables.
local swimming_speed = 66

-- Update the hero while swimming.
local function update_hero()

  if desc == "sideview_swim" then
    if speed ~= 0 then
      new_animation = "swimming_scroll"
    else
      new_animation = "stopped_swimming_scroll"
    end
  end

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
        if map:get_ground(x, y + 4, layer) == "deep_water" then
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
        if map:get_ground(x, y + 4, layer)=="deep_water" then
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
local function start_swimming(hero)
  hero.vspeed = 0
  is_swimming = true
end

-- Check for water the entity at the entity position, whatever the layer is.
function swimming_manager:is_in_water(entity)

  local map = entity:get_map()
  local x, y = entity:get_position()

  for layer = map:get_max_layer(), map:get_min_layer(), -1 do
    if map:get_ground(x, y, layer) == "deep_water" then
      return true
    end
  end
  
  return false
end

-- Return whether the water gravity process is needed.
function swimming_manager.is_water_gravity_needed(entity)

  return entity:get_type() ~= "hero" and not entity.water_processed and not entity.vspeed and entity:test_obstacles(0, 1) and is_in_water(entity)
end

-- Start water gravity on an entity
function swimming_manager.start_water_gravity(entity)
  
  entity.water_processed = true

  sol.timer.start(entity, 50, function()
    entity.water_processed = nil
    local x, y = entity:get_position()
    entity:set_position(x, y + 1)
  end)
end

-- Initialize the swimming ability.
function swimming_manager.initialize()

  local hero_meta=sol.main.get_metatable("hero")
  if hero_meta.start_swimming then
    return
  end

  function hero_meta:start_swimming()
    start_swimming(self)
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

swimming_manager.initialize()
return swimming_manager