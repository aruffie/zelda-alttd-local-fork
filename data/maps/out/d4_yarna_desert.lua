-- Variables
local map = ...
local game = map:get_game()


-- Include scripts
require("scripts/multi_events")
local travel_manager = require("scripts/maps/travel_manager")
local audio_manager = require("scripts/audio_manager")

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
  marin_1:set_enabled(false)
  marin_2:set_enabled(false)
  -- Musicians
  fox_musician:set_enabled(false)
  elephant_musician:set_enabled(false)
  bird_musician:set_enabled(false)
  monty_mole:set_enabled(false)
  -- Rabbit 4
  rabbit_4:set_enabled(false)
  -- Travel
  travel_transporter:set_enabled(false)
  -- Walrus
  if game:is_step_done("walrus_awakened") then
    walrus:set_enabled(false)
  end
  -- Ground sand
  for ground in map:get_entities('ground_sand') do
    ground:set_visible(false)
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

-- This is the cinematic in which Walris
function map:launch_cinematic_1()

  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, marin_2, companion_marin, walrus, rabbit_4, snores}
    }
    map:set_cinematic_mode(true, options)
    -- Hero
    hero:set_animation("walking")
    hero:set_direction(1)
    local movement1 = sol.movement.create("target")
    movement1:set_speed(30)
    movement1:set_target(position_link)
    movement1:set_ignore_suspend(true)
    movement(movement1, hero)
    hero:set_animation("stopped")
    hero:set_direction(3)
    wait(1000)
    -- Marin
    local x, y, layer = companion_marin:get_position()
    marin_2:set_position(x, y, layer)
    marin_2:set_enabled(true)
    companion_marin:set_enabled(false)
    marin_2:get_sprite():set_animation("walking")
    local movement2 = sol.movement.create("target")
    movement2:set_speed(30)
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
    for i=1,4 do
      audio_manager:play_sound("hero/jump")
      animation(walrus:get_sprite(), 'jumping')
      walrus:get_sprite():set_animation("waiting")
      wait(2000)
    end
    map:set_cinematic_mode(false, options)
  end)

end
