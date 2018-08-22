--[[
------------------------------------------------------
---------- UNSTABLE FLOORS MANAGER SCRIPT -----------
------------------------------------------------------

This feature is used to store the last stable floor position for the hero.
Then, you can recover it with:

  hero:get_last_stable_position()

UNSTABLE FLOORS are a custom property for entities, used to specify that we cannot use that position
to save it as a solid ground position, which is a general property of "bad grounds" too.
Recall that BAD GROUNDS include holes, lava, and also deep water only if the hero does NOT have
the "swim" ability. Unstable floors can be used on weak floors that break, perhaps on moving
platforms too, and any other type of custom grounds/floors that do not not allow saving solid ground position.

This is intended to be used by other scripts (like the jumping script), when necessary, in this way:

  hero:save_solid_ground(hero:get_last_stable_position())

------------------------------------------------------
-------------- INSTRUCTIONS FOR DUMMIES --------------
------------------------------------------------------

1) HOW TO include this feature. First, include the script with:

  require("scripts/maps/unstable_floor_manager.lua")

-Use the multi-events script if you need to add some code there or you may break the feature.
-Do NOT redefine the events "hero/hero_meta.on_position_changed" or "hero/hero_meta.on_created".
This is also called by default in the events "map.on_started", "map.on_finished" and "separator.on_activated".
-Call "hero:initialize_unstable_floor_manager()" always after calling "hero:reset_solid_ground()".

2) HOW TO define unstable floors (i.e., floors where the hero does not save position):

Create an entity and set its custom property "unstable_floor" to the string value "true",
either from the Editor, or in the script with:

  entity:set_property("unstable_floor", "true")

--]]

local map_meta = sol.main.get_metatable("map")
local hero_meta = sol.main.get_metatable("hero")
local separator_meta = sol.main.get_metatable("separator")
hero_meta.last_stable_position = {x = nil, y = nil, layer = nil}

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

-- Function to check if the position is UNSTABLE floor, i.e., a place where the solid position
-- of the hero cannot be saved. Recall that bad grounds are a particular case of unstable floors.
function map_meta:is_unstable_floor(x, y, layer)

  if self:is_bad_ground(x, y, layer) then return true end
  -- Check overlapping entities.
  for e in self:get_entities_in_rectangle(x, y, 1, 1) do
    if e:get_property("unstable_floor") == "true" and e:get_layer() == layer then
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
  if not hero:is_jumping() and hero:get_state() ~= "jumping" then
    if not map:is_unstable_floor(x, y, layer) then
      local position = hero.last_stable_position
      position.x, position.y, position.layer = hero:get_position()
    end
  end
end)

-- Function to initialize the unstable floor manager.
-- Use it always after calling "hero:reset_solid_ground()".
function hero_meta:initialize_unstable_floor_manager()

  local hero = self  
  hero:save_solid_ground(function()
    -- Return the last stable position.
    pos = hero.last_stable_position
    return pos.x, pos.y, pos.layer
  end)
end

-- Initialize the manager on the corresponding events.
hero_meta:register_event("on_created", function(hero)
  hero:initialize_unstable_floor_manager()
end)
map_meta:register_event("on_started", function(map)
  map:get_hero():initialize_unstable_floor_manager()
end)
map_meta:register_event("on_finished", function(map)
  map:get_hero():initialize_unstable_floor_manager()
end)
separator_meta:register_event("on_activated", function(separator, dir4)
  separator:get_map():get_hero():initialize_unstable_floor_manager()
end)
