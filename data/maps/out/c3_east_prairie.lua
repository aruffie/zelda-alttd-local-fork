-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")

-- Map events
function map:on_started()

  -- Music
  map:init_music()
  -- Digging
  map:set_digging_allowed(true)
  -- Ground secret
  ground_secret:set_enabled(true)
  if game:get_value("ground_secret_1") then
    bush_ground_secret:set_enabled(false)
    ground_secret:set_enabled(false)
    map:enable_ground_secret_entities()
  else
    map:disable_ground_secret_entities()
  end

end

-- Initialize the music of the map
function map:init_music()
  
  audio_manager:play_music("10_overworld")

end

-- Function that disable ground secret entities
function map:disable_ground_secret_entities()
  
  for entity in map:get_entities("ground_secret_entities_") do
    entity:set_enabled(false)
  end
  
end

-- Function that enable ground secret entities
function map:enable_ground_secret_entities()
  
  for entity in map:get_entities("ground_secret_entities_") do
    entity:set_enabled(true)
  end
  
end

-- Destructibles events
bush_ground_secret:register_event("on_cut", function()
    
  map:launch_cinematic_1()
  
end)

-- Cinematics
-- This is the cinematic that the hero cut the secret bush
function map:launch_cinematic_1()
  
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, bush_ground_secret, ground_secret}
    }
    map:set_cinematic_mode(true, options)
    sol.audio.stop_music()
    wait(1000)
    local symbol_exclamation = hero:create_symbol_exclamation()
    wait(1000)
    symbol_exclamation:remove()
    local direction = hero:get_direction4_to(ground_secret_placeholder)
    hero:set_direction(direction)
    hero:set_animation("walking")
    local movement_target = sol.movement.create("target")
    movement_target:set_target(ground_secret_placeholder)
    movement_target:set_ignore_suspend(true)
    movement(movement_target, hero)
    hero:set_direction(2)
    hero:set_animation("stopped")
    wait(1000)
    local timer_sound = sol.timer.start(hero, 0, function()
      audio_manager:play_sound("misc/dungeon_shake")
      return 450
    end)
    timer_sound:set_suspended_with_map(false)
    local camera = map:get_camera()
    local shake_config = {
      count = 32,
      amplitude = 4,
      speed = 90
    }
    wait_for(camera.shake,camera,shake_config)
    timer_sound:stop()
    wait(1000)
    map:enable_ground_secret_entities()
    audio_manager:play_sound("misc/secret1")
    animation(ground_secret:get_sprite(), "falling")
    wait(1000)
    ground_secret:set_enabled(false)
    game:set_value("ground_secret_1", true)
    map:init_music()
    map:set_cinematic_mode(false, options)
  end)

end