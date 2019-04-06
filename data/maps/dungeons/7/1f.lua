-- Lua script of map dungeons/7/1f.
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
require("scripts/multi_events")

-----------------------
-- Map events
-----------------------
function map:on_started()

  -- Owl
  owl_manager:init(map)

  -- Music
  game:play_dungeon_music()

  -- Ennemies
  enemy_manager:create_teletransporter_if_small_boss_dead(map, false)

  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_small_key_1")
end

function map:on_opening_transition_finished(destination)

  if destination == dungeon_7_1_B then
    game:start_dialog("maps.dungeons.7.welcome")
  end
end

-----------------------
-- Enemies events
-----------------------
-- Make face lamp stop shooting when other ennemies are dead
enemy_manager:on_enemies_dead(map, "enemy_group_2_", function()
  enemy_group_3_2:set_shooting(false)
end)

-----------------------
-- Treasures events
-----------------------
treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_2_", "pickable_small_key_1")

-----------------------
-- Separators
-----------------------
separator_manager:init(map)