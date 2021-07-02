-----------------------
-- Variables
-----------------------

local map = ...
local game = map:get_game()
local is_small_boss_active = false
local is_boss_active = false
local slab_group_index = 0

-----------------------
-- Include scripts
-----------------------

require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")
local door_manager = require("scripts/maps/door_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local separator_manager = require("scripts/maps/separator_manager")
local switch_manager = require("scripts/maps/switch_manager")
local treasure_manager = require("scripts/maps/treasure_manager")

-----------------------
-- Map events
-----------------------

-- Start a straight movement on an entity.
local function start_straight_movement(entity, angle, distance, speed)

  local movement = sol.movement.create("straight")
  movement:set_angle(angle)
  movement:set_max_distance(distance)
  movement:set_speed(speed)
  movement:set_smooth(false)
  movement:start(entity)
  
end

-- Move iron blocks on given angle each time the handle is pulling.
local function move_block_on_handle_pulled(block, angle, max_distance)

  pull_handle:register_event("on_pulling", function(pull_handle, movement_count)
    -- Move max_distance unless the limit is reached.
    local block_x, block_y = block:get_position()
    local distance = math.min(max_distance, math.abs(math.sin(angle) * (block_y - block.start_y)) + math.abs(math.cos(angle) * (block_x - block.start_x)))
    if distance ~= 0 then
      start_straight_movement(block, angle, distance, 10)
    end
  end)

end

-- Start movement to make iron blocks close the way out.
local function start_blocks_closing()

  start_straight_movement(block_1_1, 3 * math.pi / 2, 16 - select(2, block_1_1:get_position()) + block_1_1.start_y, 2)
  start_straight_movement(block_1_2, math.pi / 2, 16 - block_1_2.start_y + select(2, block_1_2:get_position()), 2)
  start_straight_movement(block_1_3, 0, 16 - select(1, block_1_3:get_position()) + block_1_3.start_x, 2)
  start_straight_movement(block_1_4, 2 * math.pi / 2, 16 - block_1_4.start_x + select(1, block_1_4:get_position()), 2)
  
end

-- Call start_blocks_closing when the pull handle is dropped.
local function start_blocks_closing_on_handle_dropped()

  pull_handle:register_event("on_released", function(pull_handle)
    start_blocks_closing()
  end)

end

-- Reset blocks position and start closing.
local function reset_blocks()

  for i = 1, 4 do
    local block = map:get_entity("block_1_" .. i)
    block:set_position(block.start_x, block.start_y, block.start_layer)
  end
  start_blocks_closing()
  
end

-- Reset slabs
local function reset_slabs(group, index)

  for i = 1, 5 do
    local slab = map:get_entity("slab_" .. group .. "_" .. i)
    if i <= index then
      slab:set_activated(true)
    else
      slab:set_activated(false)
    end
    if i == index + 1 then
      slab:get_sprite():set_animation('to_activate')
    elseif index == 0 then
      slab:get_sprite():set_animation('inactivated')
    end
  
  end
  slab_group_index = index
  
end

-- Init slabs
local function init_slabs(group)

  for i = 1, 5 do
    local slab = map:get_entity("slab_" .. group .. "_" .. i)
    function slab:on_activated()
      local order = tonumber(slab:get_property('order'))
      if order == slab_group_index + 1 then
        slab:get_sprite():set_animation('being_activated')
        audio_manager:play_sound("menus/menu_select")
        sol.timer.start(map, 200, function() 
          slab:get_sprite():set_animation('activated')
        end)
        slab_group_index = slab_group_index + 1
        if slab_group_index == 5 and group == 1 then
          map:open_doors("door_group_5_")
          sensor_12:set_enabled(false)
          audio_manager:play_sound("misc/secret_1")
        elseif slab_group_index == 5 and group == 2 then
          -- Todo
        end
        reset_slabs(group, slab_group_index)
      else
        reset_slabs(group, 0)
      end
    end
  end
  reset_slabs(group, 0)
  
end

map:register_event("on_started", function()

  -- Doors
  map:set_doors_open("door_group_1_", true)
  map:set_doors_open("door_group_2_", true)
  map:set_doors_open("door_group_3_", true)
  map:set_doors_open("door_group_6_", true)
  map:set_doors_open("door_group_small_boss_", true)
  door_manager:open_when_enemies_dead(map,  "enemy_group_4_",  "door_group_1_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_2_",  "door_group_2_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_1_",  "door_group_3_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_23_",  "door_group_6_")
  door_manager:open_when_switch_activated(map, "switch_1", "door_group_4_")

  -- Enemies
  enemy_manager:create_teletransporter_if_small_boss_dead(map, false)

  -- Music
  game:play_dungeon_music()

  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_small_key_1")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_8_", "pickable_small_key_1")
  treasure_manager:appear_heart_container_if_boss_dead(map)

  -- Blocks
  for i = 1, 4 do
    local block = map:get_entity("block_1_" .. i)
    block.start_x, block.start_y, block.start_layer = block:get_position()
  end
  
  -- Slabs
  
  init_slabs(1)
  
  
  -- Separators
  separator_manager:init(map)
  
end)

function map:on_obtaining_treasure(item, variant, savegame_variable)

  if savegame_variable == "dungeon_4_big_treasure" then
    treasure_manager:get_instrument(map)
  end
  
end

-----------------------
-- Entities events
-----------------------

move_block_on_handle_pulled(block_1_1, math.pi / 2, 4)
move_block_on_handle_pulled(block_1_2, 3 * math.pi / 2, 4)
move_block_on_handle_pulled(block_1_3, 2 * math.pi / 2, 4)
move_block_on_handle_pulled(block_1_4, 0, 4)
start_blocks_closing_on_handle_dropped()

-----------------------
-- Sensor events
-----------------------

function sensor_1:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_4_", "door_group_1_")
  
end

function sensor_2:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_2_", "door_group_2_")
  
end

function sensor_3:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_2_", "door_group_2_")
  
end

function sensor_4:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_4_", "door_group_1_")
  
end

function sensor_5:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_4_", "door_group_1_")
  
end

function sensor_6:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_4_", "door_group_1_")
  
end

function sensor_7:on_activated()

  door_manager:close_if_enemies_not_dead(map,  "enemy_group_1_",  "door_group_3_")
  
end

function sensor_8:on_activated()

  if is_small_boss_active == false then
    is_small_boss_active = true
    enemy_manager:launch_small_boss_if_not_dead(map)
  end
  
end

function sensor_9:on_activated()

  if is_boss_active == false then
    is_boss_active = true
    enemy_manager:launch_boss_if_not_dead(map)
  end
  
end

function sensor_10:on_activated()

  door_manager:close_if_enemies_not_dead(map,  "enemy_group_23_",  "door_group_6_")
  
end

function sensor_11:on_activated()

  sensor_10:on_activated()
  sensor_12:set_enabled(true)
  
end

function sensor_12:on_activated()

  init_slabs(1)
  map:close_doors("door_group_5_")
  
end

function sensor_13:on_activated()

  init_slabs(1)
  map:set_doors_open("door_group_5_", false)
  sensor_12:set_enabled(true)
  
end

-- Replace blocks when entering the pull handle room.
function sensor_14:on_activated()
  
  reset_blocks()
  
end

function sensor_15:on_activated()
  
  reset_blocks()
  
end