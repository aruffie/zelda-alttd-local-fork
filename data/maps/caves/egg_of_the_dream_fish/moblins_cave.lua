-- Variables
local map = ...
local game = map:get_game()
local room_access_1 = false
local room_access_2 = false
local room_access_3 = false

-- Include scripts
require("scripts/multi_events")
local door_manager = require("scripts/maps/door_manager")
local separator_manager = require("scripts/maps/separator_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events
map:register_event("on_started", function(map, destination)
  
  -- Music
  if game:is_step_last("bowwow_dognapped") then
    audio_manager:stop_music()
  else
    map:init_music()
  end
  -- Entities
  map:init_map_entities()
  -- Doors
  map:set_doors_open("door_group_", true)
  -- Enemies
  for enemy in map:get_entities("enemy_group_1") do
    enemy:get_sprite():set_direction(3)
  end
  
  -- Separators
  if game:is_step_last("bowwow_dognapped") then
    separator_manager:init(map)
  end
  
end)

-- Initialize the music of the map
function map:init_music()
  
  if game:is_step_last("bowwow_dognapped") then
    audio_manager:play_music("26_bowwow_dognapped")
  else
    audio_manager:play_music("18_cave")
  end
  
end

-- Initializes Entities based on player's progress
function map:init_map_entities()
 
  if not game:is_step_last("bowwow_dognapped") then
    for enemy in map:get_entities_by_type("enemy") do
      enemy:remove()
    end
    bowwow:remove()
    moblin_chief:remove()
    moblin_fire:remove()
    moblin_fire_light:remove()
  else
    moblin_chief:get_sprite():set_animation("sitting")
    if game:is_step_done("bowwow_joined") then
      moblin_fire:get_sprite():set_animation("off")
      moblin_fire_light:remove()
    end
  end

end

function map.do_after_transition()
  if not game:is_step_last("bowwow_dognapped") or room_access_1 then
    return
  end
  room_access_1 = true
  map:launch_cinematic_1()

end

 -- Doors
door_manager:open_when_enemies_dead(map, "enemy_group_1", "door_group_1")
door_manager:open_when_enemies_dead(map, "enemy_group_2", "door_group_1")
door_manager:open_when_enemies_dead(map, "enemy_group_2", "door_group_2")
door_manager:open_when_enemies_dead(map, "enemy_group_3", "door_group_2")
door_manager:open_when_enemies_dead(map, "enemy_group_3", "door_group_3")

-- Sensors
sensor_bowwow:register_event("on_activated", function()
  
  if not game:is_step_last("bowwow_dognapped") then
    return
  end
  for enemy in map:get_entities_by_type("enemy") do
    enemy:remove()
  end
  audio_manager:play_sound("items/fanfare_item_extended")
  map:launch_cinematic_4()

end)

-- Separators
function separator_throne:on_activated()
  
  if not game:is_step_last("bowwow_dognapped") or room_access_2 then
    return
  end

  -- Workaround: Wait a frame before launching the cinematic to avoid enemies being restarted automatically after separator:on_activated()
  sol.timer.start(map, 10, function()
    room_access_2 = true
    map:launch_cinematic_2()
  end)

end

function separator_boss:on_activated()
  
  if not game:is_step_last("bowwow_dognapped") or room_access_3 then
    return
  end
  room_access_3 = true
  map:launch_cinematic_3()

end

-- Cinematics
-- This is the cinematic that the hero enters the cave to fight the Moblins
function map:launch_cinematic_1()
  
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, moblin_fire}
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
    local symbol = enemy_group_1_1:create_symbol_exclamation(true)
    wait(2000)
    symbol:remove()
    map:init_music()
    dialog("maps.caves.egg_of_the_dream_fish.moblins_cave.moblins_1")
    door_manager:close_if_enemies_not_dead(map, "enemy_group_1", "door_group_1")
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
    sol.timer.stop_all(enemy)
    enemy:stop_movement()
    local sprite = enemy:get_sprite()
    sprite:set_animation("stopped")
    sprite:set_direction(1)
  end
  hero:freeze() -- Stop any running custom state.
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, moblin_chief, enemy_group_2_1, enemy_group_2_2, enemy_group_2_3, enemy_group_2_4}
    }
    map:set_cinematic_mode(true, options)
    hero:set_animation("walking")
    local m = sol.movement.create("target")
    m:set_target(placeholder_hero_1)
    m:set_ignore_suspend(true)
    m:set_speed(40)
    movement(m, hero)
    hero:set_animation("stopped")
    enemy_group_2_1:get_sprite():set_direction(3)
    local symbol_1 = enemy_group_2_1:create_symbol_exclamation(true)
    wait(200)
    enemy_group_2_2:get_sprite():set_direction(3)
    local symbol_2 = enemy_group_2_2:create_symbol_exclamation(true)
    wait(200)
    enemy_group_2_3:get_sprite():set_direction(3)
    local symbol_3 = enemy_group_2_3:create_symbol_exclamation(true)
    wait(200)
    enemy_group_2_4:get_sprite():set_direction(3)
    local symbol_4 = enemy_group_2_4:create_symbol_exclamation(true)
    wait(200)
    local symbol_5 = moblin_chief:create_symbol_exclamation(true)
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
    dialog("maps.caves.egg_of_the_dream_fish.moblins_cave.moblins_2")
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
    door_manager:close_if_enemies_not_dead(map, "enemy_group_2", "door_group_2")
    wall_enemies:remove()
    map:set_cinematic_mode(false, options)
    for enemy in map:get_entities("enemy_group_2") do
      enemy:restart()
    end
  end)

end

-- This is the cinematic that the hero enters in the same room that the moblin chief bis
function map:launch_cinematic_3()

  hero:freeze() -- Stop any running custom state.
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, enemy_group_3_1}
    }
    map:set_cinematic_mode(true, options)
    hero:set_animation("walking")
    local m = sol.movement.create("straight")
    m:set_angle(0)
    m:set_max_distance(48)
    m:set_ignore_suspend(true)
    m:set_speed(40)
    movement(m, hero)
    hero:set_animation("stopped")
    --enemy_group_3_1:get_sprite():set_animation("prepare_attacking")
    --enemy_group_3_1:get_sprite():set_direction(2)
    dialog("maps.caves.egg_of_the_dream_fish.moblins_cave.moblins_3")
    map:set_cinematic_mode(false, options)
    door_manager:close_if_enemies_not_dead(map, "enemy_group_3", "door_group_2")
    door_manager:close_if_enemies_not_dead(map, "enemy_group_3", "door_group_3")
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
    game:set_step_done("bowwow_joined")
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
      sprite = "npc/animals/bowwow",
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