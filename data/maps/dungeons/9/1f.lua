-- Lua script of map dungeons/9/1f.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local separator = ...
local game = map:get_game()

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
  --Great Fairy gone if we already have the tunic (?)
  if game:get_value("get_tunic") then map:set_entities_enabled("great_fairy",false) sensor_6:set_enabled(false) end

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

function weak_door_1:on_opened() audio_manager:play_sound("misc/secret1") end

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
  audio_manager:play_music("fairy_fountain")
end
function sensor_7:on_activated()
  map:close_doors("door_group_7")
end

-- Switchs events

function switch_5:on_activated()
  audio_manager:play_sound("misc/secret1")
  map:open_doors("door_group_5")
end

--Miniboss 1
function miniboss_sensor_1:on_activated()
    hero:freeze()
    map:close_doors("door_miniboss_1")
    sol.audio.stop_music()
    sol.timer.start(1000,function()
      hero:unfreeze()
      miniboss_1:set_enabled(true)
      audio_manager:play_music("small_boss")
      miniboss_sensor_1:set_enabled(false)
    end)
end
if miniboss_1 ~= nil then
 function miniboss_1:on_dead()
  audio_manager:play_sound("misc/secret1") 
  audio_manager:play_music("maps/dungeons/9/dungeon")
  map:open_doors("door_miniboss_1") 
 end
end
--Miniboss 2
function miniboss_sensor_2:on_activated()
    hero:freeze()
    map:close_doors("door_miniboss_2")
    sol.audio.stop_music()
    sol.timer.start(1000,function()
      hero:unfreeze()
      miniboss_2:set_enabled(true)
      audio_manager:play_music("small_boss")
      miniboss_sensor_2:set_enabled(false)
    end)
end
if miniboss_2 ~= nil then
 function miniboss_2:on_dead()
  audio_manager:play_sound("misc/secret1") 
  audio_manager:play_music("maps/dungeons/9/dungeon")
  map:open_doors("door_miniboss_2") 
 end
end

--Boss
function boss_sensor:on_activated()
    hero:freeze()
    map:close_doors("door_boss")
    sol.audio.stop_music()
    sol.timer.start(1000,function()
      hero:unfreeze()
      boss:set_enabled(true)
      audio_manager:play_music("boss")
      boss_sensor:set_enabled(false)
    end)
end
if boss ~= nil then
 function boss:on_dead()
  audio_manager:play_sound("misc/secret1") 
  audio_manager:play_music("maps/dungeons/9/dungeon")
  map:open_doors("door_boss") 
 end
end

--Great Fairy
local tunic_answer
local function fairy_dialog()
  game:start_dialog("maps.dungeons.9.great_fairy.sure",function(answer)
    if answer == 1 then
      hero:start_treasure("tunic",tunic_answer + 1,"get_tunic",function()
        game:start_dialog("maps.dungeons.9.great_fairy.closing_eyes",function()
            local opacity = 0
            local white_surface =  sol.surface.create(320, 256)
            white_surface:fill_color({255, 255, 255})
            function map:on_draw(dst_surface)
              white_surface:set_opacity(opacity)
              white_surface:draw(dst_surface)
              opacity = opacity + 1
              if opacity > 255 then
                opacity = 255
              end
            end
            sol.timer.start(3000, function()
                game:start_dialog("maps.dungeons.9.great_fairy.end", function()
                  hero:teleport("out/b2_graveyard","dungeon_9_exit","fade")
                end)
            end)
        end)
      end)
    else
      game:start_dialog("maps.dungeons.9.great_fairy.repeat",function(answer)
        if answer == 1 then tunic_answer = 1 else tunic_answer = 2 end
        fairy_dialog()
      end)
    end
  end)
end

function great_fairy:on_interaction()
  great_fairy:set_enabled(false)
  game:start_dialog("maps.dungeons.9.great_fairy.welcome",function(answer)
    if answer == 1 then tunic_answer = 1 else tunic_answer = 2 end
    fairy_dialog()
  end)
end


owl_manager:init(map)