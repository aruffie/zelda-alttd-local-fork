-- Lua script of map dungeons/7/2f.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

-----------------------
-- Variables
-----------------------
local map = ...
local game = map:get_game()

-----------------------
-- Include scripts
-----------------------
local audio_manager = require("scripts/audio_manager")
local door_manager = require("scripts/maps/door_manager")
local treasure_manager = require("scripts/maps/treasure_manager")
local switch_manager = require("scripts/maps/switch_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local separator_manager = require("scripts/maps/separator_manager")
local owl_manager = require("scripts/maps/owl_manager")
local flying_tile_manager = require("scripts/maps/flying_tile_manager")
local map_tools = require("scripts/maps/map_tools")
require("scripts/multi_events")

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

-- Move iron blocks on y axis each time the handle is pulling.
local function move_block_on_handle_pulled(block, angle, max_distance)
  pull_handle:register_event("on_pulling", function(pull_handle, movement_count)
    -- Move max_distance unless the limit is reached.
    local _, block_y = block:get_position()
    local distance = math.min(max_distance, math.abs(block_y - block.start_y))
    if distance ~= 0 then
      local x, y, layer = block:get_position()
      start_straight_movement(block, angle, distance, 10)
    end
  end)
end

-- Start movement to make iron blocks close the way out.
local function start_blocks_closing()
  start_straight_movement(block_1_1, 3 * math.pi / 2, 16, 2)
  start_straight_movement(block_1_2, math.pi / 2, 16, 2)
end

-- Call start_blocks_closing when the pull handle is dropped.
local function start_blocks_closing_on_handle_dropped()
  pull_handle:register_event("on_released", function(pull_handle)
    start_blocks_closing()
  end)
end

-- Save iron ball position when the throw ends.
local function save_iron_ball_position_on_finish_throw()
  iron_ball:register_event("on_finish_throw", function()
    map_tools.save_entity_position(iron_ball)
  end)
end

-- Break the given entities when hit by the iron ball.
local function start_breaking_on_hit_by_iron_ball(entities_prefix)
  for entity in map:get_entities(entities_prefix) do
    entity:register_event("on_hit_by_carriable", function(entity, carriable)   
      if carriable:get_name() == "iron_ball" and entity:is_enabled() then
        map_tools.start_earthquake({count = 64, amplitude = 4, speed = 90}) -- Start the earthquake when the hit occurs.
        carriable:register_event("on_finish_throw", function(carriable)
          entity:start_breaking() -- Start breaking the pillar when the iron ball is immobilized.
        end)
      end
    end)
  end
end

-- Tower collapsing cinematic.
local function start_tower_cinematic()
  -- TODO
  print("TODO Insert tower cinematic here")
end

-- Start tower collapsing cinematic when all given pillars are broken.
local function start_tower_cinematic_on_all_collapse_finished(pillar_prefix)
  for pillar in map:get_entities(pillar_prefix) do
    pillar:register_event("on_collapse_finished", function()
      are_all_pillar_broken = true
      for pillar in map:get_entities(pillar_prefix) do
        if pillar:is_enabled() then
          are_all_pillar_broken = false
        end
      end
      if are_all_pillar_broken then
        start_tower_cinematic()
      end
    end)
  end
end

function map:on_started()

  -- Owl
  owl_manager:init(map)

  -- Chests
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_map", "dungeon_7_map")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_compass", "dungeon_7_compass")
  treasure_manager:appear_chest_if_savegame_exist(map, "chest_bomb_1", "dungeon_7_bomb_1")

  -- Doors
  map:set_doors_open("door_group_2_", true)
  door_manager:open_weak_wall_if_savegame_exist(map, "weak_wall_A", "dungeon_7_weak_wall_A")
  door_manager:open_weak_wall_if_savegame_exist(map, "weak_wall_B", "dungeon_7_weak_wall_B")

  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_small_key_3")

  -- Ennemies
  flying_tile_manager:init(map, "enemy_group_10")

  -- Entities
  iron_ball:set_position(map_tools.get_entity_saved_position(iron_ball)) -- Keep iron ball position even if the game was closed.

  -- Blocks
  block_1_1.start_x, block_1_1.start_y, block_1_1.start_layer = block_1_1:get_position()
  block_1_2.start_x, block_1_2.start_y, block_1_2.start_layer = block_1_2:get_position()
end

-----------------------
-- Doors events
-----------------------
wallturn:add_collision_test("touching", function(wallturn, hero)
  door_group_1_1:set_open()
  flying_tile_manager:reset(map, "enemy_group_10")
end)

sensor_1:register_event("on_activated", function()
  map:close_doors("door_group_1_")
  map:close_doors("door_group_2_")
  flying_tile_manager:launch(map, "enemy_group_10")
end)

door_manager:open_when_flying_tiles_dead(map, "enemy_group_10", "door_group_2_")

weak_wall_A_1:register_event("on_opened", function()
  door_manager:destroy_wall(map, "weak_wall_A")
end)

weak_wall_B_1:register_event("on_opened", function()
  door_manager:destroy_wall(map, "weak_wall_B")
end)

-----------------------
-- Enemies events
-----------------------
enemy_manager:execute_when_vegas_dead(map, "enemy_group_3_")
enemy_manager:execute_when_vegas_dead(map, "enemy_group_7_")
hinox_master:register_event("on_dead", function(hinox_master)
  enemy_group_8_1:set_shooting(false) -- Face lamps
  enemy_group_8_2:set_shooting(false)
end)
enemy_group_8_1:set_shooting(game:get_value("dungeon_7_hinox_master") or false)
enemy_group_8_2:set_shooting(game:get_value("dungeon_7_hinox_master") or false)

-----------------------
-- Treasures events
-----------------------
treasure_manager:appear_chest_when_horse_heads_upright(map, "horse_head_", "chest_map")
treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_3_", "chest_compass")
treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_7_", "chest_bomb_1")
treasure_manager:appear_pickable_when_enemies_dead(map, "hinox_master", "pickable_small_key_3")

-----------------------
-- Entities events
-----------------------
move_block_on_handle_pulled(block_1_1, math.pi / 2, 4)
move_block_on_handle_pulled(block_1_2, 3 * math.pi / 2, 4)
start_blocks_closing_on_handle_dropped()
save_iron_ball_position_on_finish_throw()
start_breaking_on_hit_by_iron_ball("pillar_")
start_tower_cinematic_on_all_collapse_finished("pillar_")

-----------------------
-- Separators
-----------------------
-- Replace blocks in the iron ball room.
auto_separator_3:register_event("on_activating", function(separator, direction4)
  if direction4 == 0 then
    block_1_1:set_position(block_1_1.start_x, block_1_1.start_y, block_1_1.start_layer)
    block_1_2:set_position(block_1_2.start_x, block_1_2.start_y, block_1_2.start_layer)
    start_blocks_closing()
  end
end)
auto_separator_5:register_event("on_activating", function(separator, direction4)
  if direction4 == 1 then
    block_1_1:set_position(block_1_1.start_x, block_1_1.start_y, block_1_1.start_layer)
    block_1_2:set_position(block_1_2.start_x, block_1_2.start_y, block_1_2.start_layer)
    start_blocks_closing()
  end
end)

separator_manager:init(map)