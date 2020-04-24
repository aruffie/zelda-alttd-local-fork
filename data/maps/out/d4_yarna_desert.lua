-- Variables
local map = ...
local game = map:get_game()


-- Include scripts
require("scripts/multi_events")
local owl_manager = require("scripts/maps/owl_manager")
local travel_manager = require("scripts/maps/travel_manager")
local audio_manager = require("scripts/audio_manager")
local parchment = require("scripts/menus/parchment")

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  -- Entities
  map:init_map_entities()
  -- Digging
  map:set_digging_allowed(true)
  -- Owl slab
  if game:get_value("travel_4") then
    owl_slab:get_sprite():set_animation("activated")
  end

end)

-- Initialize the music of the map
function map:init_music()
  
  audio_manager:play_music("40_animal_village")

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
  
  -- Marin
  if not game:is_step_done("walrus_awakened") then
    marin_1:set_enabled(false)
    -- Musicians
    fox_musician:set_enabled(false)
    elephant_musician:set_enabled(false)
    bird_musician:set_enabled(false)
    monty_mole:set_enabled(false)
  end
  marin_2:set_enabled(false)
  -- Owl 8
  owl_8:set_enabled(false)
  -- Rabbit 4
  rabbit_4:set_enabled(false)
  -- Travel
  travel_transporter:set_enabled(false)
  -- Walrus
  if game:is_step_done("walrus_awakened") then
    walrus:set_enabled(false)
    walrus_invisible:set_enabled(false)
    walrus_wall:set_enabled(false)
    snores:set_enabled(false)
  end
  -- Ground sand
  for ground in map:get_entities('ground_sand') do
    ground:set_visible(false)
  end
  -- Initialise the quicksand hole on the magnet position.
  local x, y, layer = magnet:get_position()
  map:create_dynamic_tile({
    name = "quicksand_hole",
    x = x - 8,
    y = y - 8,
    layer = layer,
    width = 16,
    height = 16,
    pattern = "2852"
  })
end

local function start_tracking_hero()

  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero},
      no_black_stripes = true
    }
    map:set_cinematic_mode(true, options)
    local camera = map:get_camera()
    local camera_x, camera_y = camera:get_position()
    local movement_camera = sol.movement.create("target")
    local x,y = camera:get_position_to_track(hero)
    movement_camera:set_speed(256)
    movement_camera:set_target(x,y)
    movement_camera:set_ignore_obstacles(true)
    movement_camera:set_ignore_suspend(true)
    movement(movement_camera, camera)
    camera:start_tracking(hero)
    audio_manager:play_music("10_overworld")
    map:set_cinematic_mode(false)
  end)

end

local function is_over_quicksand(entity)

  local x, y, _ = entity:get_position()
  return x > 480 and x < 784 and y < 224 -- Hardcode quicksand position since there is no custom ground.
end

function map:leave_boss()

  magnet:stop_attracting()

  if game:is_step_done("sandworm_killed") then
    return
  end

  if boss and boss:exists() then
    boss:set_enabled(false)
  end
  start_tracking_hero()

end

-- Launch Boss
function map:launch_boss()

  -- Make magnet attract the hero when his position is over the quicksand.
  magnet:start_attracting(hero, 40, false, function()
    return is_over_quicksand(hero)
  end)

  if game:is_step_done("sandworm_killed") then
    return
  end

  -- Stop music
  sol.audio.stop_music()
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero}
    }
    map:set_cinematic_mode(true, options)
    local camera = map:get_camera()
    local camera_x, camera_y = camera:get_position()
    local movement_camera = sol.movement.create("target")
    local x,y = camera:get_position_to_track(position_boss)
    movement_camera:set_speed(64)
    movement_camera:set_target(x,y)
    movement_camera:set_ignore_obstacles(true)
    movement_camera:set_ignore_suspend(true)
    movement(movement_camera, camera)
    if not boss then
      x_boss, y_boss, layer_boss = position_boss:get_position()
      map:create_enemy({
        name = "boss",
        breed = "boss/desert_lanmola",
        x = x_boss,
        y = y_boss,
        layer = layer_boss,
        direction = 0,
        treasure_name = "angler_key",
        treasure_savegame_variable = "yarna_desert_angler_key"
      })
      boss:register_event("on_dead", function()
        for item in map:get_entities_by_type("pickable") do
          local treasure = item:get_treasure()
          if treasure:get_name() == "angler_key" then
            
            -- Hardcode a timer before attracting the key to let the it fall on the ground before attracting.
            sol.timer.start(item, 800, function()
              magnet:start_attracting(item, 40, true, function()
                return is_over_quicksand(item)
              end)
            end)
          end
        end
        start_tracking_hero()
        game:set_step_done("sandworm_killed") 
      end)
    elseif boss:exists() then
      boss:set_enabled(true)
      boss:set_life(8)
    end
    local line_1 = sol.language.get_dialog("maps.out.yarna_desert.boss_name").text
    local line_2 = sol.language.get_dialog("maps.out.yarna_desert.boss_description").text
    parchment:show(map, "boss", "top", 1500, line_1, line_2, nil, function()

    end)
    audio_manager:play_music("22_boss_battle")
    
    map:set_cinematic_mode(false)
    
  end)

end  

-- Obtaining angler key
function map:on_obtaining_treasure(treasure_item, treasure_variant, treasure_savegame_variable)

  if treasure_item:get_name() == "angler_key" then
    game:set_step_done("dungeon_4_key_obtained")
  end

end

-- Discussion with Rabbit 1
function map:talk_to_rabbit_1()

  game:start_dialog("maps.out.yarna_desert.rabbit_1_1")

end

-- Discussion with Rabbit 2
function map:talk_to_rabbit_2()

  game:start_dialog("maps.out.yarna_desert.rabbit_2_1")

end

-- Discussion with Rabbit 3
function map:talk_to_rabbit_3()

  game:start_dialog("maps.out.yarna_desert.rabbit_3_1")

end

-- Discussion with Walrus
function map:talk_to_walrus()

  if game:is_step_last("marin_joined") then
    game:start_dialog("maps.out.yarna_desert.marin_1", function(answer)
      if answer == 1 then
        map:launch_cinematic_1()
      else
        game:start_dialog("maps.out.yarna_desert.marin_4")
      end
    end)
  else
    game:start_dialog("maps.out.yarna_desert.walrus_1")
  end

end

-- Doors events
function weak_door_1:on_opened()

  audio_manager:play_sound("misc/secret1")

end

-- NPCs events
function rabbit_1:on_interaction()

  map:talk_to_rabbit_1()

end

function rabbit_2:on_interaction()

  map:talk_to_rabbit_2()

end

function rabbit_3:on_interaction()

  map:talk_to_rabbit_3()

end

function walrus_invisible:on_interaction()

  map:talk_to_walrus()

end

-- Sensors events
function travel_sensor:on_activated()

  travel_manager:init(map, 4)
  
end

function sensor_boss_1:on_activated()
  
  map:launch_boss()
  
end

function sensor_boss_2:on_activated()
  
  map:launch_boss()

  
end

function sensor_boss_3:on_activated()
  
  map:leave_boss()
  
end

function sensor_boss_4:on_activated()
  
  map:leave_boss()

  
end

-- Sensors events
function owl_8_sensor:on_activated()

  if not map:get_game():get_value("owl_8") and game:is_step_last("dungeon_4_key_obtained") then
    owl_manager:appear(map, 8, function()
      map:init_music()
    end)
  end

end


-- Separators events
separator_1:register_event("on_activating", function(separator, direction4)

  if direction4 == 1 then
    audio_manager:play_music("40_animal_village")
  elseif direction4 == 3 then
    audio_manager:play_music("10_overworld")
  end

end)

separator_2:register_event("on_activating", function(separator, direction4)
    
  if direction4 == 0 then
    map.fsa_heat_wave = true
  elseif direction4 == 2 then
    map.fsa_heat_wave = false
  end
  
end)

-- This is the cinematic in which Walrus wakes up
function map:launch_cinematic_1()

  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, marin_2, companion_marin, walrus, rabbit_4, snores}
    }
    map:set_cinematic_mode(true, options)
    sol.audio.stop_music()
    -- Hero
    hero:set_animation("walking")
    hero:set_direction(1)
    local movement1 = sol.movement.create("target")
    movement1:set_speed(50)
    movement1:set_target(position_link)
    movement1:set_ignore_suspend(true)
    movement(movement1, hero)
    hero:set_animation("stopped")
    hero:set_direction(1)
    wait(500)
    -- Marin
    local x, y, layer = companion_marin:get_position()
    marin_2:set_position(x, y, layer)
    marin_2:set_enabled(true)
    companion_marin:set_enabled(false)
    marin_2:get_sprite():set_animation("walking")
    local movement2 = sol.movement.create("target")
    movement2:set_speed(50)
    movement2:set_target(position_marin)
    movement2:set_ignore_suspend(true)
    movement2:set_ignore_obstacles(true)
    movement(movement2, marin_2)
    marin_2:get_sprite():set_direction(0)
    wait(1000)
    marin_2:sing_start()
    wait(1000)
    snores:remove()
    animation(walrus:get_sprite(), 'awakening')
    for i=1,5 do
      audio_manager:play_sound("hero/jump")
      animation(walrus:get_sprite(), 'jumping')
      walrus:get_sprite():set_animation("waiting")
      wait(1500)
    end
    local movement3 = sol.movement.create("jump")
    movement3:set_speed(96)
    movement3:set_direction8(6)
    movement3:set_distance(96)
    movement3:set_ignore_suspend(true)
    movement3:set_ignore_obstacles(true)
    movement3:start(walrus)
    animation(walrus:get_sprite(), 'diving')
    audio_manager:play_sound("hero/cliff_jump")
    walrus:get_sprite():set_animation("sinking")
    wait(500)
    x_walrus, y_walrus, layer_walrus = walrus:get_position()
    local splash_walrus = map:create_custom_entity({
      sprite = "entities/ground_effects/walrus_diving_effect",
      x = x_walrus,
      y = y_walrus - 16,
      width = 48,
      height = 32,
      layer = layer_walrus,
      direction = 0
    })
    walrus:set_enabled(false)
    walrus_wall:set_enabled(false)
    walrus_invisible:set_enabled(false)
    marin_2:sing_stop()
    marin_2:get_sprite():set_direction(3)
    audio_manager:play_music("10_overworld")
    wait(1000)
    splash_walrus:remove()
    dialog("maps.out.yarna_desert.marin_2")
    -- Rabbit 4
    rabbit_4:set_enabled(true)
    local x_rabbit_4, y_rabbit_4, layer_rabbit_4 = rabbit_4:get_position()
    marin_2:get_sprite():set_direction(2)
    hero:set_direction(2)
    local symbol_marin = marin_2:create_symbol_exclamation(true)
    local symbol_hero = hero:create_symbol_exclamation()
    local movement4 = sol.movement.create("target")
    movement4:set_speed(64)
    movement4:set_target(position_rabbit_4)
    movement4:set_ignore_suspend(true)
    movement4:set_ignore_obstacles(true)
    movement(movement4, rabbit_4)
    rabbit_4:get_sprite():set_animation("jumping")
    symbol_marin:remove()
    symbol_hero:remove()
    dialog("maps.out.yarna_desert.marin_3")
    marin_2:get_sprite():set_direction(3)
    hero:set_direction(1)
    dialog("maps.out.yarna_desert.marin_5")
    rabbit_4:get_sprite():set_animation("walking")
    rabbit_4:get_sprite():set_direction(2)
    local movement5 = sol.movement.create("target")
    movement5:set_speed(64)
    movement5:set_target(x_rabbit_4, y_rabbit_4)
    movement5:set_ignore_suspend(true)
    movement5:set_ignore_obstacles(true)
    movement5:start(rabbit_4)
    local movement6 = sol.movement.create("target")
    movement6:set_speed(50)
    movement6:set_target(x_rabbit_4, y_rabbit_4)
    movement6:set_ignore_suspend(true)
    movement6:set_ignore_obstacles(true)
    movement(movement6, marin_2)
    marin_2:set_enabled(false)
    rabbit_4:set_enabled(false)
    for i=1,2 do
      animation(hero, "happy")
    end
    game:set_step_done("walrus_awakened") 
    map:set_cinematic_mode(false, options)
  end)

end
