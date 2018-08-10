-- Lua script of map dungeons/9/1f.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local separator = ...
local game = map:get_game()
local companion_manager = require("scripts/maps/companion_manager")
local is_boss_active = false

local door_manager = require("scripts/maps/door_manager")
local treasure_manager = require("scripts/maps/treasure_manager")
local switch_manager = require("scripts/maps/switch_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local owl_manager = require("scripts/maps/owl_manager")

function map:on_started()

  --Miniboss 1
  if game:get_value("dungeon_9_miniboss_1") then 
    miniboss_sensor_1:set_enabled(false) 
  else miniboss_1:set_enabled(false) end
  --Miniboss 2
  if game:get_value("dungeon_9_miniboss_2") then 
    miniboss_sensor_2:set_enabled(false) 
  else miniboss_2:set_enabled(false) end
  --Boss
  if game:get_value("dungeon_9_boss") then 
    boss_sensor:set_enabled(false) 
  else boss:set_enabled(false) end

end

function map:on_opening_transition_finished(destination)

  map:set_doors_open("door_group_1", true)
  map:set_doors_open("door_group_2", true)
  map:set_doors_open("door_group_3", true)
  map:set_doors_open("door_group_5", true)
  map:set_doors_open("door_group_6", true)
  map:set_doors_open("door_group_7", true)

  map:set_doors_open("door_miniboss_1")
  map:set_doors_open("door_miniboss_2")
  map:set_doors_open("door_boss")

  if destination == entrance then
    game:start_dialog("maps.dungeons.9.welcome")
  end

end

-- Doors

door_manager:open_when_enemies_dead(map,  "enemy_group_1_",  "door_group_1")
door_manager:open_when_enemies_dead(map,  "enemy_group_2_",  "door_group_2")
door_manager:open_when_enemies_dead(map,  "enemy_group_3_",  "door_group_3")
door_manager:open_when_enemies_dead(map,  "enemy_group_5_",  "door_group_5")

function weak_door_1:on_opened() sol.audio.play_sound("secret_1") end

-- Sensors events

function sensor_1:on_activated()
  door_manager:close_if_enemies_not_dead(map, "enemy_group_1_", "door_group_1")
end
function sensor_2:on_activated()
  door_manager:close_if_enemies_not_dead(map, "enemy_group_2_", "door_group_2")
end
function sensor_3:on_activated()
  door_manager:close_if_enemies_not_dead(map, "enemy_group_3_", "door_group_3")
end
function sensor_4_1:on_activated()
  map:open_doors("door_group_4")
end
function sensor_4_2:on_activated()
  map:close_doors("door_group_4")
end
function sensor_5:on_activated()
  map:close_doors("door_group_5")
end
function sensor_6:on_activated()
  map:close_doors("door_group_6")
end
function sensor_7:on_activated()
  map:close_doors("door_group_7")
end

-- Switchs events

function switch_5:on_activated()
  sol.audio.play_sound("secret_1")
  map:open_doors("door_group_5")
end

--Miniboss 1
function miniboss_sensor_1:on_activated()
    hero:freeze()
    map:close_doors("door_miniboss_1")
    sol.audio.play_music("none")
    sol.timer.start(1000,function()
      hero:unfreeze()
      miniboss_1:set_enabled(true)
      sol.audio.play_music("maps/dungeons/small_boss")
      miniboss_sensor_1:set_enabled(false)
    end)
end
if miniboss_1 ~= nil then
 function miniboss_1:on_dead()
  sol.audio.play_sound("secret_1") 
  sol.audio.play_music("maps/dungeons/9/dungeon")
  map:open_doors("door_miniboss_1") 
 end
end
--Miniboss 2
function miniboss_sensor_2:on_activated()
    hero:freeze()
    map:close_doors("door_miniboss_2")
    sol.audio.play_music("none")
    sol.timer.start(1000,function()
      hero:unfreeze()
      miniboss_2:set_enabled(true)
      sol.audio.play_music("maps/dungeons/small_boss")
      miniboss_sensor_2:set_enabled(false)
    end)
end
if miniboss_2 ~= nil then
 function miniboss_2:on_dead()
  sol.audio.play_sound("secret_1") 
  sol.audio.play_music("maps/dungeons/9/dungeon")
  map:open_doors("door_miniboss_2") 
 end
end

--Boss
function boss_sensor:on_activated()
    hero:freeze()
    map:close_doors("door_boss")
    sol.audio.play_music("none")
    sol.timer.start(1000,function()
      hero:unfreeze()
      boss:set_enabled(true)
      sol.audio.play_music("maps/dungeons/boss")
      boss_sensor:set_enabled(false)
    end)
end
if boss ~= nil then
 function boss:on_dead()
  sol.audio.play_sound("secret_1") 
  sol.audio.play_music("maps/dungeons/9/dungeon")
  map:open_doors("door_boss") 
 end
end


owl_manager:manage_map(map)