-- Lua script of map dungeons/4/1f.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local separator = ...
local game = map:get_game()
local is_small_boss_active = false
local is_boss_active = false

local door_manager = require("scripts/maps/door_manager")
local treasure_manager = require("scripts/maps/treasure_manager")
local switch_manager = require("scripts/maps/switch_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local separator_manager = require("scripts/maps/separator_manager")
local owl_manager = require("scripts/maps/owl_manager")

function map:on_started()

 local hero = map:get_hero()
  -- Init music
  game:play_dungeon_music()



end

function map:on_opening_transition_finished(destination)

  if destination == dungeon_4_1_B then
    game:start_dialog("maps.dungeons.4.welcome")
  end

end


-- Enemies


-- Treasures


-- Doors

door_manager:open_when_enemies_dead(map,  "enemy_group_4",  "door_group_1")

-- Blocks


-- Sensors events


separator_manager:manage_map(map)
owl_manager:manage_map(map)

