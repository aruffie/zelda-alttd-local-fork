--[[
------------------------------------------------------
---------- UNSTABLE GROUNDS MANAGER SCRIPT -----------
------------------------------------------------------

This feature is used to store the last stable ground position for the hero.
Then, you can recover it with:

  hero:get_last_stable_position()

UNSTABLE GROUNDS are a CUSTOM type of ground, used to specify that we cannot use that position
to save it as a solid ground position. Unstable grounds are a CUSTOM generalization of bad grounds.
Recall that BAD GROUNDS include holes, lava, and also deep water only if the hero does NOT have
the "swim" ability. Unstable grounds can be used on weak grounds that break, perhaps on moving
platforms too, and any other type of custom ground that does not allow saving solid ground position.

This is intended to be used by other scripts (like the jumping script), when necessary, in this way:

  hero:save_solid_ground(hero:get_last_stable_position())

------------------------------------------------------
-------------- INSTRUCTIONS FOR DUMMIES --------------
------------------------------------------------------

1) HOW TO include this feature. First, include the script with:

  require("scripts/maps/unstable_ground_manager.lua")

Second, do NOT redefine the events "hero/hero_meta.on_position_changed" or "hero/hero_meta.on_created".
Use the multi-events script if you need to add some code there or you will break the feature!!!!

2) HOW TO define unstable grounds (i.e., grounds where the hero does not save position):

Create an entity and set its custom property "unstable_ground" to the string value "true",
either from the Editor, or in the script with:

  entity:set_property("unstable_ground", "true")

--]]

local map_meta = sol.main.get_metatable("map")
local hero_meta = sol.main.get_metatable("hero")
hero_meta.last_stable_position = {x = nil, y = nil, layer = nil}
hero_meta.saved_solid_position = {parameter_type = nil, x = nil, y = nil, layer = nil, my_function = nil}

-- We will need to redefine these built-in functions.
hero_meta.original_save_solid_ground = hero_meta.save_solid_ground
hero_meta.original_reset_solid_ground = hero_meta.reset_solid_ground
hero_meta.save_solid_ground = nil
hero_meta.reset_solid_ground = nil

-- Function to check if the position is BAD ground, i.e., holes, lava, and maybe deep water too.
-- Deep water is ONLY considered bad ground if the hero does NOT have the "swim" ability.
function map_meta:is_bad_ground(x, y, layer)

  local game = self:get_game()
  local ground = self:get_ground(x, y, layer)
  if ground == "hole" or ground == "lava" or 
      (ground == "deep_water" and game:get_ability("swim") == 0) then
    return true
  end
  return false
end

-- Function to check if the position is UNSTABLE ground, i.e., a place where the solid position
-- of the hero cannot be saved. Recall that bad grounds are a particular case of unstable grounds.
function map_meta:is_unstable_ground(x, y, layer)

  if self:is_bad_ground(x, y, layer) then return true end
  -- Check overlapping entities.
  for e in self:get_entities_in_rectangle(x, y, 1, 1) do
    if e:get_property("unstable_ground") == "true" and e:get_layer() == layer then
      return true
    end
  end
  return false
end

-- Return last stable position of the hero.
function hero_meta:get_last_stable_position()

  local pos = self.last_stable_position
  return pos.x, pos.y, pos.layer
end

-- Update the last stable position of the hero.
hero_meta:register_event("on_position_changed", function(hero)

  local map = hero:get_map()
  local x, y, layer = hero:get_ground_position() -- Check GROUND position.
  local position = hero.last_stable_position
  if not hero:is_jumping() and hero:get_state() ~= "jumping" then
    if not map:is_unstable_ground(x, y, layer) then
      position.x, position.y, position.layer = hero:get_position()
    end
  end
end)

-- Redefine the built-in function "hero_meta.reset_solid_ground".
function hero_meta:reset_solid_ground()

  self.saved_solid_position = {}
end

-- Redefine the built-in function "hero_meta.save_solid_ground" in both cases.
function hero_meta:save_solid_ground(x, y, layer)

  local hero = self
  if type(x) == "function" then -- Function parameter.
    hero.saved_solid_position = {parameter_type = "function",
        x = nil, y = nil, layer = nil, my_function = x}  
  elseif x and y then -- Position coordinates. For compatibility with the Lua API, allow a nil layer.
    if not layer then layer = hero:get_layer() end
    hero.saved_solid_position = {parameter_type = "coordinates",
        x = x, y = y, layer = layer, my_function = nil}
  else -- Nil parameters. For compatibility with the Lua API, reset saved position.
    hero.saved_solid_position = {}
  end
end

-- Define the callback for the built-in function "hero.save_solid_ground".
-- THIS IS TRICKY: we need an instance of hero to call it, so we need to register
-- the callback in the event "hero_meta.on_created". This callback will NEVER be
-- overriden because we have redefined the built-in functions!!!
hero_meta:register_event("on_created", function(hero)

  hero:original_save_solid_ground(function()
    -- If there is a saved position or callback position stored, return it.
    -- Otherwise, return the last stable position that we have stored.
    local pos = hero.saved_solid_position
    local x, y, layer, my_function, par_type = pos.x, pos.y, pos.layer, pos.my_function, pos.parameter_type
    -- Case 1: return coordinates.
    if par_type == "coordinates" then
      return x, y, layer
    -- Case 2: return function parameter.
    elseif par_type == "function" then
      return my_function()
    -- Case 3: since no position is saved, return the last stable position.
    else
      pos = hero.last_stable_position
      return pos.x, pos.y, pos.layer
    end
  end)
end)
