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
-- Save iron ball position when the throw ends.
local function save_iron_ball_position_on_finish_throw()
  iron_ball:register_event("on_finish_throw", function()
    map_tools.save_entity_position(iron_ball)
  end)
end

-- Call entity:start_breaking() when one of the given entity is hit by the iron ball.
local function start_breaking_on_hit_by_iron_ball(entities_prefix)
  for entity in map:get_entities(entities_prefix) do
    entity:register_event("on_hit_by_carriable", function(entity, carriable)   
      if carriable:get_name() == "iron_ball" then
        entity:start_breaking()
      end
    end)
  end
end

-- Tower collapsing cinematic.
local function start_tower_cinematic()
  -- TODO
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
  treasure_manager:disappear_pickable(map, "pickable_small_key_2")

  -- Ennemies
  flying_tile_manager:init(map, "enemy_group_10")

  -- Entities
  iron_ball:set_position(map_tools.get_entity_saved_position(iron_ball)) -- Keep iron ball position even if the game was closed.
end

-- TODO Move blocks "block_1_" when handle is pulled

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
  doors_manager:destroy_wall(map, "weak_wall_A")
end)

weak_wall_B_1:register_event("on_opened", function()
  doors_manager:destroy_wall(map, "weak_wall_B")
end)

-----------------------
-- Enemies events
-----------------------
enemy_manager:execute_when_vegas_dead(map, "enemy_group_3_")
enemy_manager:execute_when_vegas_dead(map, "enemy_group_7_")

-----------------------
-- Treasures events
-----------------------
treasure_manager:appear_chest_when_horse_heads_upright(map, "horse_head_", "chest_map")
treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_3_", "chest_compass")
treasure_manager:appear_chest_when_enemies_dead(map, "enemy_group_7_", "chest_bomb_1")
treasure_manager:appear_pickable_when_enemies_dead(map, "hinox_master", "pickable_small_key_2")

-----------------------
-- Entities events
-----------------------
save_iron_ball_position_on_finish_throw()
start_breaking_on_hit_by_iron_ball("pillar_")
start_tower_cinematic_on_all_collapse_finished("pillar_")

-----------------------
-- Separators
-----------------------
separator_manager:init(map)