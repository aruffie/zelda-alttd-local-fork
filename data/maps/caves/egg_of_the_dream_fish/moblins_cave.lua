-- Variables
local map = ...
local game = map:get_game()
local launch_boss = false

-- Include scripts
require("scripts/multi_events")
local door_manager = require("scripts/maps/door_manager")
local separator_manager = require("scripts/maps/separator_manager")

-- Map events
function map:on_started(destination)

  map:init_music()
  map:init_map_entities()
  
end

-- Initialize the music of the map
function map:init_music()
  
  if game:get_value("main_quest_step") == 9  then
    sol.audio.play_music("maps/out/moblins_and_bow_wow")
  else
    sol.audio.play_music("maps/caves/cave")
  end
  
end

-- Initializes Entities based on player's progress
function map:init_map_entities()
 
  local step = game:get_value("main_quest_step")
  if step ~= 9 then
    for enemy in map:get_entities_by_type("enemy") do
      enemy:remove()
    end
    bowwow:remove()
    map:set_doors_open("door_group", true)
  end
  -- Moblin chief
  moblin_chief:get_sprite():set_animation("sitting")
  -- Moblin fire
  if step < 9 then
    moblin_fire:set_enabled(false)
  elseif step > 9 then
    moblin_fire:get_sprite():set_animation("off")
  end

end

function map:on_opening_transition_finished(destination)

  local step = game:get_value("main_quest_step")
  if step ~= nil and step ~= 9 then
    return
  end
  map:launch_cinematic_1()

end

 -- Doors
door_manager:open_when_enemies_dead(map,  "enemy_group_1",  "door_group_1")
door_manager:open_when_enemies_dead(map,  "enemy_group_2",  "door_group_1")
door_manager:open_when_enemies_dead(map,  "enemy_group_3",  "door_group_1")

function sensor_2:on_activated()

  local step = game:get_value("main_quest_step")
  if step ~= nil and step ~= 9 then
    return
  end
  map:launch_cinematic_2()

end

function sensor_3:on_activated()

  local step = game:get_value("main_quest_step")
  if step ~= nil and step ~= 9 then
    return
  end
  if launch_boss then
    return
  end
  launch_boss = true
  door_manager:close_if_enemies_not_dead(map, "enemy_group_3", "door_group_1")
  game:start_dialog("maps.caves.egg_of_the_dream_fish.moblins_cave.moblins_2", function()
    enemy_group_3_1:start_battle()
  end)

end

function sensor_4:on_activated()

  local step = game:get_value("main_quest_step")
  if step ~= nil and step ~= 9 then
    return
  end
  for enemy in map:get_entities_by_type("enemy") do
    enemy:remove()
  end
  sol.audio.play_sound("treasure_2")
  game:start_dialog("maps.caves.egg_of_the_dream_fish.moblins_cave.bowwow_1", function()
    game:set_value("main_quest_step", 10)
    local x,y, layer = bowwow:get_position()
    local name =  bowwow:get_name()
    bowwow:remove()
    bowwow = map:create_custom_entity({
        name = "bowwow",
        sprite = "npc/bowwow",
        x = x,
        y = y,
        width = 16,
        height = 16,
        layer = layer,
        direction = 0,
        model =  "bowwow_follow"
      })
  end)

end

local step = game:get_value("main_quest_step")
if step == 9 then
  separator_manager:manage_map(map)
end

-- Cinematics
-- This is the cinematic that the hero enters the cave to fight the Mloblins
function map:launch_cinematic_1()
  
  map:set_doors_open("door_group_1", true)
  door_manager:close_if_enemies_not_dead(map, "enemy_group_1", "door_group_1")
  for enemy in map:get_entities("enemy_group_1") do
    enemy:get_sprite():set_direction(3)
  end
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, enemy_group_1_1}
    }
    map:set_cinematic_mode(true, options)
    dialog("maps.caves.egg_of_the_dream_fish.moblins_cave.moblins_1")
    for enemy in map:get_entities("enemy_group_1") do
      local direction = enemy:get_movement():get_direction4()
      enemy:get_sprite():set_direction(direction)
    end
    map:set_cinematic_mode(false, options)
  end)

end

-- This is the cinematic that the hero enters in the same room that the moblin chief
function map:launch_cinematic_2()
  
  local game = map:get_game()
  local x_moblin_chief, y_moblin_chief = moblin_chief:get_position()
  moblin_chief:get_sprite():set_animation("sitting_text")
  moblin_chief:get_sprite():set_direction(0)
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, enemy_group_1_1}
    }
    map:set_cinematic_mode(true, options)
    local alignement = game:get_dialog_box():get_position()
    dialog.set_vertical_alignment("bottom")
    dialog("maps.caves.egg_of_the_dream_fish.moblins_cave.moblins_3")
    game:get_dialog_box():set_position(alignement)
    moblin_chief:get_sprite():set_animation("walking")
    moblin_chief:get_sprite():set_ignore_suspend(true)
    moblin_chief.xy = { x = x_moblin_chief, y = y_moblin_chief }
    local m = sol.movement.create("target")
    m:set_speed(96)
    m:set_target(moblin_chief_finished)
    m:set_ignore_obstacles(true)
    m:set_ignore_suspend(true)
    movement(m, moblin_chief)
    moblin_chief:set_enabled(false)
    door_manager:close_if_enemies_not_dead(map, "enemy_group_2", "door_group_1")
    map:set_cinematic_mode(false, options)
  end)

end