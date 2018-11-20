-- Variables
local map = ...
local game = map:get_game()
local launch_boss = false

-- Include scripts
require("scripts/multi_events")
local door_manager = require("scripts/maps/door_manager")
local separator_manager = require("scripts/maps/separator_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events
function map:on_started(destination)
  
  -- Music
  if game:get_value("main_quest_step") == 9  then
    sol.audio.stop_music()
  else
    map:init_music()
  end
  -- Entities
  map:init_map_entities()
  -- Doors
  map:set_doors_open("door_group_1", true)
  -- Ennemies
  for enemy in map:get_entities("enemy_group_1") do
    enemy:get_sprite():set_direction(3)
  end
  
end

-- Initialize the music of the map
function map:init_music()
  
  if game:get_value("main_quest_step") == 9  then
    audio_manager:play_music("26_bowwow_dognapped")
  else
    audio_manager:play_music("18_cave")
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
  if step ~= 9 then
    moblin_chief:remove()
  else
      moblin_chief:get_sprite():set_animation("sitting")
  end
  -- Moblin fire
  if step < 9 then
    moblin_fire:remove()
    moblin_fire_light:remove()
  elseif step > 9 then
    moblin_fire:get_sprite():set_animation("off")
    moblin_fire_light:remove()
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

-- Sensors
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
  map:launch_cinematic_3()

end

-- NPCs events
function bowwow:on_interaction()

  local step = game:get_value("main_quest_step")
  if step ~= nil and step ~= 9 then
    return
  end
  for enemy in map:get_entities_by_type("enemy") do
    enemy:remove()
  end
  audio_manager:play_sound("treasure_2")
  map:launch_cinematic_4()

end

-- Cinematics
-- This is the cinematic that the hero enters the cave to fight the Moblins
function map:launch_cinematic_1()
  
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, enemy_group_1_1, moblin_fire}
    }
    map:set_cinematic_mode(true, options)
    -- Movement
    hero:set_animation("walking")
    local m = sol.movement.create("straight")
    m:set_angle(math.pi/2)
    m:set_max_distance(32)
    m:set_ignore_suspend(true)
    m:set_speed(40)
    movement(m, hero)
    hero:set_animation("stopped")
    local symbol = enemy_group_1_1:create_symbol_exclamation()
    wait(2000)
    symbol:remove()
    map:init_music()
    dialog("maps.caves.egg_of_the_dream_fish.moblins_cave.moblins_1")
    door_manager:close_if_enemies_not_dead(map, "enemy_group_1", "door_group_1")
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
  for enemy in map:get_entities("enemy_group_2") do
    enemy:get_sprite():set_direction(3)
  end
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, moblin_chief, enemy_group_2_1, enemy_group_2_2, enemy_group_2_3, enemy_group_2_4}
    }
    map:set_cinematic_mode(true, options)
    -- Movement
    hero:set_animation("walking")
    local m = sol.movement.create("target")
    m:set_target(placeholder_hero_1)
    m:set_ignore_suspend(true)
    m:set_speed(40)
    movement(m, hero)
    hero:set_animation("stopped")
    local symbol_1 = enemy_group_2_1:create_symbol_exclamation()
    wait(200)
    local symbol_2 = enemy_group_2_2:create_symbol_exclamation()
    wait(200)
    local symbol_3 = enemy_group_2_3:create_symbol_exclamation()
    wait(200)
    local symbol_4 = enemy_group_2_4:create_symbol_exclamation()
    wait(200)
    local symbol_5 = moblin_chief:create_symbol_exclamation()
    wait(2000)
    symbol_1:remove()
    symbol_2:remove()
    symbol_3:remove()
    symbol_4:remove()
    symbol_5:remove()    
    -- Dialog box
    local dialog_box = game:get_dialog_box()
    local alignement = dialog_box:get_position()
    dialog_box.set_position("bottom")
    dialog("maps.caves.egg_of_the_dream_fish.moblins_cave.moblins_3")
    game:get_dialog_box():set_position(alignement)
    moblin_chief:get_sprite():set_animation("walking")
    moblin_chief:get_sprite():set_ignore_suspend(true)
    moblin_chief.xy = { x = x_moblin_chief, y = y_moblin_chief }
    -- Init movement
    local m = sol.movement.create("target")
    m:set_speed(96)
    m:set_target(moblin_chief_finished)
    m:set_ignore_obstacles(true)
    m:set_ignore_suspend(true)
    movement(m, moblin_chief)
    moblin_chief:set_enabled(false)
    door_manager:close_if_enemies_not_dead(map, "enemy_group_2", "door_group_1")
    for enemy in map:get_entities("enemy_group_2") do
      local direction = enemy:get_movement():get_direction4()
      enemy:get_sprite():set_direction(direction)
    end
    wall_enemies:remove()
    map:set_cinematic_mode(false, options)
  end)

end

-- This is the cinematic that the hero enters in the same room that the moblin chief bis
function map:launch_cinematic_3()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_3", "door_group_1")
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, enemy_group_3_1}
    }
    map:set_cinematic_mode(true, options)
    enemy_group_3_1:get_sprite():set_animation("prepare_attacking")
    enemy_group_3_1:get_sprite():set_direction(2)
    dialog("maps.caves.egg_of_the_dream_fish.moblins_cave.moblins_2")
    map:set_cinematic_mode(false, options)
    enemy_group_3_1:start_battle()
  end)

end

-- This is the cinematic that the hero retrieve bowow
function map:launch_cinematic_4()
  
  local game = map:get_game()
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero}
    }
    map:set_cinematic_mode(true, options)
    -- Movement
    hero:set_animation("happy")
    local sprite = hero:get_sprite()
    local time = sprite:get_frame_delay() * sprite:get_num_frames()
    local timer = sol.timer.start(map, time, function()
      hero:set_animation("happy")
      return true
    end)
    timer:set_suspended_with_map(false)
    hero:set_direction(3)
    dialog("maps.caves.egg_of_the_dream_fish.moblins_cave.bowwow_1")
    timer:stop()
    game:set_value("main_quest_step", 10)
    hero:set_animation("walking")
    hero:set_direction(0)
    local m = sol.movement.create("target")
    m:set_speed(40)
    m:set_target(placeholder_hero_2)
    m:set_ignore_obstacles(true)
    m:set_ignore_suspend(true)
    movement(m, hero)
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
      model =  "follower"
    })
    hero:set_animation("stopped")
    wait(1000)
    hero:set_animation("walking")
    hero:set_direction(2)
    local m = sol.movement.create("straight")
    m:set_angle(math.pi)
    m:set_ignore_obstacles(true)
    m:set_ignore_suspend(true)
    m:set_max_distance(64)
    movement(m, hero)
    map:set_cinematic_mode(false, options)
  end)

end

-- Separators
local step = game:get_value("main_quest_step")
if step == 9 then
  separator_manager:init(map)
end