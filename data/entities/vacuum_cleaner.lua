-- Variables
local entity = ...
local map = entity:get_map()
local game = map:get_game()
local hero = map:get_hero()
local speed = 30 -- Change this for a different speed.
local needs_destruction -- Destroy if "action" or "attack" commads are pressed.
local next_direction
local interaction_finished = false -- True if first interaction has finished (command released).
local sprite = "entities/vacuum_cleaner_ground" -- [TODO: change default value]. Used to create ground sprites.

-- Include scripts
require("scripts/multi_events")

-- Event called when the custom entity is initialized.
entity:register_event("on_created", function()
  
  entity:set_traversable_by(false)
  entity:set_can_traverse_ground("lava", true)
  entity:set_can_traverse_ground("hole", true)
  for _, ground in pairs({"empty", "traversable", "wall",
      "low_wall", "wall_top_right", "wall_top_left", "wall_bottom_left",
      "wall_bottom_right", "wall_top_right_water", "wall_top_left_water", 
      "wall_bottom_left_water", "wall_bottom_right_water", "deep_water",
      "shallow_water", "grass", "ice", "ladder", "prickles"}) do
    entity:set_can_traverse_ground(ground, false)
  end
  
end)

-- Return the direction pressed, if any.
-- Return nil if no direction or more than one direction is pressed.
function entity:get_direction_pressed()
  
  local dir_names = {[0] = "right", "up", "left", "down"}
  local dir_pressed
  local num_directions = 0
  for dir = 0, 3 do
    if game:is_command_pressed(dir_names[dir]) then
      num_directions = num_directions + 1
      dir_pressed = dir
    end
  end
  if num_directions ~= 1 then
    return
  end
  
  return dir_pressed
  
end

function entity:check_commands_pressed()
  -- Check if needs destruction.
  sol.timer.start(entity, 20, function()
    if interaction_finished and game:is_command_pressed("action")
        or game:is_command_pressed("attack") then
      needs_destruction = true
      return true -- Stop timer.
    end
    return true -- Repeat timer.
  end)
  -- Update new direction if necessary.
  sol.timer.start(entity, 20, function()
    local dir = entity:get_direction_pressed()
    if dir ~= nil then
      next_direction = dir
      return false -- Stop timer.
    end
    return true -- Repeat timer.
  end)
end

function entity:move()
  
  -- Check commands.
  sol.timer.stop_all(entity)
  entity:check_commands_pressed()
  -- TODO: start the moving sound with a timer.

  -- Create traversable tile (custom entity!).
  local tile = entity:create_tile()
  -- Create movement.
  local m = sol.movement.create("path")
  m:set_path({2*next_direction, 2*next_direction}) -- Move 16 pixels.
  m:set_speed(speed)
  m:set_snap_to_grid(true)
  m:start(entity)
  -- Destroy if an "obstacle ground" is reached.
  function m:on_obstacle_reached() 
    tile:set_modified_ground("traversable")
    entity:remove()
  end
  -- Continue movement or destroy if necessary.
  function m:on_finished()
    tile:set_modified_ground("traversable")
    if needs_destruction then entity:remove() end
    entity:move()
  end
  
end

-- Start using the vacuum cleaner.
entity:register_event("on_interaction", function()
  
  hero:freeze()
  hero:set_invincible()
  next_direction = hero:get_direction()
  entity:move()
  -- Notify when command action has been released after first interaction.
  sol.timer.start(map, 20, function()
    if not game:is_command_pressed("action") then
      interaction_finished = true
      return
    end
    return true
  end)

end)

entity:register_event("on_removed", function()
  
  -- TODO: make the disappearing effects: sound and animation.
  hero:set_invincible(false)
  hero:unfreeze()  
  
end)

-- Functions to initialize tile pattern from the map script.
function entity:get_tile_sprite()
  
  return sprite

end
function entity:set_tile_sprite(new_sprite)
  
  sprite = new_sprite
  
end

function entity:create_tile()
  
  local x, y, layer = entity:get_position()
  local prop = {x = x, y = y, layer = layer, direction = 0, width = 16, height = 16, sprite = sprite}
  local tile = entity:get_map():create_custom_entity(prop)
  tile:bring_to_back()
  tile:snap_to_grid()
  
  return tile
  
end