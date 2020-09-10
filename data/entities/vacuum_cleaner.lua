-- Variables
local entity = ...
local map = entity:get_map()
local game = map:get_game()
local hero = map:get_hero()
local camera = map:get_camera()
local speed = 30 -- Change this for a different speed.
local needs_destruction -- Destroy if "action" or "attack" commads are pressed.
local next_direction
local interaction_finished = false -- True if first interaction has finished (command released).
local sprite = "entities/vacuum_cleaner_ground" -- [TODO: change default value]. Used to create ground sprites.
local tiles = {}
local is_first_move = true

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

-- Start a standalone sprite animation on the enemy position, that will be removed once finished or maximum_duration reached if given.
local function start_brief_effect(sprite_name, animation_name, x_offset, y_offset, on_finished_callback)

  local x, y, layer = entity:get_position()
  local effect = map:create_custom_entity({
      sprite = sprite_name,
      x = x + (x_offset or 0),
      y = y + (y_offset or 0),
      layer = layer,
      width = 80,
      height = 32,
      direction = 0
  })
  effect:set_drawn_in_y_order()

  -- Remove the entity once animation finished or max_duration reached.
  local function on_finished()
    if on_finished_callback then
      on_finished_callback()
    end
    effect:remove()
  end
  local sprite = effect:get_sprite()
  sprite:set_animation(animation_name or sprite:get_animation(), function()
    on_finished()
  end)

  return effect
end

-- Return the vacuum sprite.
function entity:get_tile_sprite()
  return sprite
end

-- Set vacuum sprite.
function entity:set_tile_sprite(new_sprite)
  sprite = new_sprite
end

-- Create a floor tile as new custom entity.
function entity:create_tile()
  
  local x, y, layer = entity:get_position()
  local prop = {x = x, y = y, layer = layer, direction = 0, width = 16, height = 16, sprite = sprite}
  local tile = entity:get_map():create_custom_entity(prop)
  tile:bring_to_back()
  tile:snap_to_grid()
  table.insert(tiles, tile)
  
  return tile
end

-- Return the direction pressed, or nil if no direction or more than one direction is pressed.
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

-- Start checking for command pressed.
function entity:check_commands_pressed()

  -- Check if needs destruction.
  sol.timer.start(entity, 20, function()
    if interaction_finished and game:is_command_pressed("action")
        or game:is_command_pressed("attack") then
      needs_destruction = true
      return false -- Stop timer.
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

-- Disable vacuum cleaner and keep it alive while created tiles are needed.
function entity:destroy()

  -- Hide the vacuum cleaner.
  sol.timer.stop_all(entity)
  entity:stop_movement()
  entity:set_visible(false)
  entity:set_traversable_by(true)

  -- Disappearing effects and sound.
  start_brief_effect("entities/effects/sparkle_small", "default", 0, 0)
  audio_manager:play_sound("misc/dungeon_open")

  -- Free hero.
  hero:set_invincible(false)
  hero:unfreeze()  
end

-- Move the entity by 16 pixels.
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
    if entity.on_all_holes_filled and entity:has_filled_all_holes() then
      entity:on_all_holes_filled()
    end
    entity:destroy()
  end
  -- Continue movement or destroy if necessary.
  function m:on_finished()
    entity:set_can_traverse_ground("traversable", false)
    tile:set_modified_ground("traversable")
    if needs_destruction then entity:destroy() end
    entity:move()
  end
end

-- Return true if all visible holes are filled.
function entity:has_filled_all_holes()

  local _, _, layer = entity:get_position()
  local camera_x, camera_y = camera:get_position()
  local camera_width, camera_height = camera:get_size()

  for x = camera_x + 8, camera_x + camera_width, 16 do
    for y = camera_y + 8, camera_y + camera_height, 16 do
      if map:get_ground(x, y, layer) == "hole" then
        return false
      end
    end
  end
  return true
end

-- Destroy created tiles on removed.
entity:register_event("on_removed", function()

  for _, tile in ipairs(tiles) do
    tile:remove()
  end
end)

-- Setup vacuum traversable properties.
entity:register_event("on_created", function()
  
  entity:set_traversable_by(false)
  entity:set_can_traverse_ground("lava", true)
  entity:set_can_traverse_ground("hole", true)
  entity:set_can_traverse_ground("traversable", true) -- Allow the first move to go through traversable to handle starting on floor.
  for _, ground in pairs({"empty", "wall",
      "low_wall", "wall_top_right", "wall_top_left", "wall_bottom_left",
      "wall_bottom_right", "wall_top_right_water", "wall_top_left_water", 
      "wall_bottom_left_water", "wall_bottom_right_water", "deep_water",
      "shallow_water", "grass", "ice", "ladder", "prickles"}) do
    entity:set_can_traverse_ground(ground, false)
  end
end)

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
