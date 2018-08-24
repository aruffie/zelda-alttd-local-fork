-- Sideview feature script.
--[[
INFO: This scripts implements gravity for sideview maps.

Pickables always fall by default. 
To allow gravity on entities there are 2 options:
1) Use "g_" as prefix in the entity name.
2) Define the custom property "sidemap_gravity" different from nil.

TODO:
A) Implement different gravity in water, and manage movements in water.
B) Implement unstable grounds for lava, prickles, holes, platforms, etc.

--]]

require("scripts/multi_events")
local map_meta = sol.main.get_metatable("map")
map_meta.side_view = false

local gravity_delay = 5 -- Delay for the gravity timer.
local update_timer -- Used to release up/down commands.
local gravity_timer -- Used for gravity.

-- Getter/setter for sideview feature.
function map_meta:is_side_view()
  return self.side_view
end
function map_meta:set_side_view(active)
  if active == self.side_view then return end
  if active then
    self:launch_side_view()
  elseif (not active) then
    gravity_timer:stop(); gravity_timer = nil
    update_timer:stop(); update_timer = nil
  end
  self.side_view = active
end


-- Initialize gravity timer for falling feature.
function map_meta:launch_side_view()

  local map = self
  local game = self:get_game()
  local hero = self:get_hero()

  -- Ignore up/down arrows when necessary.
  map:register_event("on_command_pressed", function(map, command)
    if command ~= "up" and command ~= "down" then return false end
    -- Allow to move in ladders.
    local x, y, layer = hero:get_position()
    if (command == "down" and map:get_ground(x, y + 3, layer) == "ladder") 
      or (command == "up" and map:get_ground(x, y - 4, layer) == "ladder") then
      return false
    end
    -- Change direction in free and jumping states, but do not move.
    game:simulate_command_released(command)
    if hero:get_state() == "free" then
      local dir = (command == "up") and 1 or 3
      hero:set_direction(dir)
      return true
    end
    -- Do not override in other cases.
    return false 
  end)

  -- Start gravity timer.
  gravity_timer = sol.timer.start(gravity_delay, function()    
    -- Check if feather is being used, if hero is on ladder, and if there is space below.
    local x, y, layer = hero:get_position()
    local is_jumping = hero.is_jumping and hero:is_jumping()
    local is_grabbed_to_ladder = map:get_ground(x, y - 4, layer) == "ladder"
        or map:get_ground(x, y + 3, layer) == "ladder"
    local is_space_below = not hero:test_obstacles(0, 1)

    -- Make the hero fall.
    if (not is_jumping) and (not is_grabbed_to_ladder) and is_space_below then
      hero:set_position(x, y + 1, layer) -- Shift position.
      if hero:test_obstacles(0, 1) then
        sol.audio.play_sound("hero_lands") -- Landing sound.
      end
    end

    -- Allow other entities to fall with the gravity timer.
    -- Pickables always fall by default. Entities with "g_" prefix or defining
    -- the custom property "sidemap_gravity" different from nil will fall.
    for entity in self:get_entities("g_") do
      -- Check entitites that can fall.
      local name = entity:get_name() or ""
      local has_g_prefix = str:sub(1, 2) == "g_"
      local has_property = entity:get_property("sidemap_gravity")
      local is_pickable = entity:get_type() == "pickable"
      -- Make entity fall.
      if has_g_prefix or has_property or is_pickable then
        local gx, gy, gl = entity:get_position()
        if not entity:test_obstacles(0, 1) then
          entity:set_position(gx, (gy + 1), gl)
        end
      end
    end

    return true
  end)

  -- Start update timer. Its delay is independent from gravity_delay.
  update_timer = sol.timer.start(10, function()
    -- Get properties.
    local x, y, layer = hero:get_position()
    local is_on_ladder = hero:get_ground_below() == "ladder"
    local is_grabbed_to_ladder = map:get_ground(x, y - 4, layer) == "ladder"
        or map:get_ground(x, y + 3, layer) == "ladder"
    local state = hero:get_state()
    -- Make the hero look up on ladders.
    if is_on_ladder and state == "free" then
      hero:set_direction(1)
    end
    -- Release "up" and "down" commands when grabbed to ladders. This avoids a bug where
    -- the the hero can fall slower/faster when up/down are pressed before on the ladder.
    if not is_grabbed_to_ladder then
      game:simulate_command_released("up")
      game:simulate_command_released("down")
    end

    return true
  end)

end

  