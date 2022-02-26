----------------------------------
--
-- Sideview swimming feature.
--
----------------------------------
local swimming_manager = {}
local sv_utils = require("scripts/tools/sideview_utils")

-- Global variables.
local is_swimming = false
local inertia_angle
local inertia_speed
local inertia_timers = {}

-- Configuration variables.
local swimming_speed = 66
local walking_hspeed = 1
local water_inertia_decrease = 0.1

-- Update entity water inertia.
local function update_water_inertia(hero)

  inertia_speed = inertia_speed - water_inertia_decrease
end

-- Start the hero swim.
local function start_swimming(hero)

  is_swimming = true
  local game = hero:get_game()

  local vspeed = -hero.vspeed or 0
  local hspeed = game:is_command_pressed("right") and walking_hspeed or game:is_command_pressed("left") and -walking_hspeed or 0
  inertia_angle = 1.5 * math.pi --math.atan2(vspeed, hspeed)
  inertia_speed = 88 --math.sqrt(vspeed * vspeed + hspeed * hspeed)

  hero.inertia_timer = sol.timer.start(hero, 10, function()
    update_water_inertia(hero)
    return 10
  end)
end

-- Stop the hero swim.
local function stop_swimming(hero)

  is_swimming = false
end

-- Update the hero while swimming.
local function update_hero(hero)
  local state, cstate = hero:get_state()
  local desc = cstate and cstate:get_description() or ""
  local x, y, layer = hero:get_position()
  local new_animation
  local movement = hero:get_movement()
  local speed = movement and movement:get_speed() or 0
  
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
      if hero.has_grabbed_ladder and sv_utils:check_for_ladder(hero) then
        new_animation = "climbing_walking"
      elseif not sv_utils:is_on_ground(hero) then
        if map:get_ground(x, y + 4, layer) == "deep_water" then
          new_animation ="swimming_scroll"
        else
          new_animation = "jumping"
        end
      else
        new_animation = "walking"
      end
    else
      if hero.has_grabbed_ladder and sv_utils:check_for_ladder(hero) then
        new_animation = "climbing_stopped"
      elseif not sv_utils:is_on_ground(hero) then
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

-- Check for water at the entity position, whatever the layer is.
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

-- Initialize the swimming ability.
function swimming_manager.initialize()

  -- Hero metatable.
  local hero_meta = sol.main.get_metatable("hero")
  if hero_meta.start_swimming then
    return
  end

  function hero_meta:start_swimming()
    start_swimming(self)
  end

  function hero_meta:is_swimming()
    return is_swimming
  end

  -- Game metatable.
  local game_meta = sol.main.get_metatable("game")
  game_meta:register_event("on_map_changed", function(game, map)
    is_swimming = false
  end)
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