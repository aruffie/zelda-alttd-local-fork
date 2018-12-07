-- Sideview feature script.
--[[
INFO: This scripts implements gravity for sideview maps.

Import this script and call in map.on_started or in
map.on_opening_transition_finished this line:

  map:launch_sideview()

Pickables always fall by default. 
To allow gravity on entities there are 2 options:
1) Use "g_" as prefix in the entity name.
2) Define the custom property "sidemap_gravity" different from nil.

TODO:
A) Implement different gravity in water, and manage movements in water.
B) Implement unstable grounds for lava, prickles, holes, platforms, etc.

--]]

require("scripts/multi_events")

local audio_manager = require("scripts/audio_manager")

local map_meta = sol.main.get_metatable("map")
map_meta.sideview = false

local gravity_delay = 5 -- Delay for the gravity timer.
local update_timer -- Release up/down commands when leaving ladders, and fix direction.
local gravity_timer -- Used for gravity.
local game, map, hero

-- Getter/setter for sideview feature.
function map_meta:is_sideview()
  return self.sideview
end
function map_meta:set_sideview(active)
  if active == self.sideview then return end
  if active then
    self:launch_sideview()
  elseif (not active) then
    gravity_timer:stop(); gravity_timer = nil
    update_timer:stop(); update_timer = nil
  end
  self.sideview = active
end


-- Create sideview menu, to override commands.
local sideview_menu = {}
map_meta.sideview_menu = sideview_menu
function map_meta:get_sideview_menu() return self.sideview_menu end

-- Define on_command_pressed event for sideview menu.
function sideview_menu:on_command_pressed(command)

  local state = hero:get_state()

  -- Free state.
  if state == "free" then

    -- Ignore up/down arrows when necessary.
    if command == "up" or command == "down" then
      -- Allow to move in ladders.
      local x, y, layer = hero:get_position()
      if (command == "down" and map:get_ground(x, y + 3, layer) == "ladder") 
          or (command == "up" and map:get_ground(x, y - 4, layer) == "ladder") then
        return false
      end
      -- Change direction in free and jumping states, but do not move.
      game:simulate_command_released(command)
      local dir = (command == "up") and 1 or 3
      hero:set_direction(dir)
      return true

    elseif command == "action" then
      -- Do not allow to use boots in up/down directions.
      sol.timer.start(300, function() -- Delay to show the animation.
        if hero:get_state() == "running" and (hero:get_direction() % 2 == 1) then
          game:simulate_command_released(command)  
        end
      end)
    end

  end
end


-- Initialize gravity timer for falling feature.
function map_meta:launch_sideview()

  -- Initialize script variables.
  map = self
  game = self:get_game()
  hero = self:get_hero()

  -- Start sideview menu.
  local menu = map:get_sideview_menu()
  sol.menu.start(map, menu, true)

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
        audio_manager:play_sound("hero/land")
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

    local state = hero:get_state()

    -- Free state.
    if state == "free" then

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

    end
    return true
  end)

end
