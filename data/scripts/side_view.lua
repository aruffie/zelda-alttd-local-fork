-- Sideview feature script.

require("scripts/multi_events")
local map_meta = sol.main.get_metatable("map")
map_meta.side_view = false

local jump_height = 40 -- Max height for jumping.
local gravity_delay = 10 -- Delay for the gravity timer.
local gravity_timer

-- Getter/setter for sideview feature.
function map_meta:is_side_view()
  return self.side_view ~= nil
end
function map_meta:set_side_view(active)
  if active and (not self.side_view) then
    self:launch_side_view()
  elseif (not active) and self.side_view then
    gravity_timer:stop(); gravity_timer = nil
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
    if hero:get_state() == "free" then
      local dir = "up" and 1 or 3
      hero:set_direction(dir)
print("asdfasdf")
      return true
    end
    -- Do not override in other cases.
    return false 
  end)


  gravity_timer = sol.timer.start(gravity_delay, function()    
    -- Check if feather is being used, if hero is on ladder, and if there is space below.
    local x, y, layer = hero:get_position()
    local is_jumping = hero.is_jumping and hero:is_jumping()
    local is_on_ladder = hero:get_ground_below() == "ladder"
    local is_grabbed_to_ladder = map:get_ground(x, y - 4, layer) == "ladder"
        or map:get_ground(x, y + 3, layer) == "ladder"
    local is_space_below = not hero:test_obstacles(0, 1)
    -- Make the hero fall.
    if (not is_jumping) and (not is_grabbed_to_ladder) and is_space_below then
      hero:set_position(x, y + 1, layer)
      --if hero:test_obstacles(0, 1) then
        --sol.audio.play_sound("hero_lands") --------------------------- SOUND BUG (UP KEY)
      --end


    end

    -- Make the hero look up on ladders.
    local state = hero:get_state()
    if is_on_ladder and state == "free" then
      hero:set_direction(1)
    end
    -- Make the hero jump.
    --if is_jumping

     
       --sol.timer.start(gravity * jump_height, function()

--[[
        if state ~= "jumping" then 
          for entity in self:get_entities("g_") do
            local gx, gy, gl = entity:get_position()
            if not entity:test_obstacles(0, 1) then
              entity:set_position(gx, (gy + 1), gl)
            end
          end
        end
--]]
    return true
  end)
end

  