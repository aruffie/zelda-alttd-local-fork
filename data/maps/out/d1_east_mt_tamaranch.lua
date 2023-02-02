-- Variables
local map = ...
local game = map:get_game()
local hero = map:get_hero()

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

end)

-- Initialize the music of the map
function map:init_music()
  
  local x_hero, y_hero = hero:get_position()
  if y_hero < 384 then
    audio_manager:play_music("46_tal_tal_mountain_range")
  else
    audio_manager:play_music("10_overworld")
  end

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
  
  -- Dungeon 7
  dungeon_7_highest_layer:get_sprite():set_animation("highest_layer")
  dungeon_7_highest_layer:set_enabled(false)
  if game:get_value("dungeon_7_opened") then
    map:open_dungeon_7()
  end
  -- Travel
  travel_transporter:set_enabled(false)
  -- Owl slab
  if game:get_value("travel_3") then
    owl_slab:get_sprite():set_animation("activated")
  end
  
end

-- Dungeon 7 opening
function map:open_dungeon_7()

  dungeon_7:get_sprite():set_animation("opened")
  dungeon_7:set_traversable_by(true)
  dungeon_7_highest_layer:set_enabled(true)
  for wall in map:get_entities("dungeon_7_wall_") do
    wall:set_enabled(true)
  end

end

-- Doors events
function weak_door_1:on_opened()
  
  audio_manager:play_sound("misc/secret1")
  
end

-- NPCs events
function dungeon_7_lock:on_interaction()

  if not game:get_value("possession_bird_key") then
    game:start_dialog("maps.out.east_mt_tamaranch.dungeon_7_lock")
  elseif not game:get_value("dungeon_7_opened") then
    map:launch_cinematic_1()
  end
  
end

-- Sensors events
function travel_sensor:on_activated()

  travel_manager:init(map, 3)

end

-- Cinematics
-- This is the cinematic in which the hero open dungeon 7 with bird key
function map:launch_cinematic_1()

  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {dungeon_7}
    }
    map:set_cinematic_mode(true, options)
    sol.audio.stop_music()
    audio_manager:play_sound("misc/chest_open")
    local camera = map:get_camera()
    local camera_x, camera_y = camera:get_position()
    local movement1 = sol.movement.create("straight")
    movement1:set_angle(0)
    movement1:set_max_distance(72)
    movement1:set_speed(75)
    movement1:set_ignore_suspend(true)
    movement1:set_ignore_obstacles(true)
    movement(movement1, camera)
    wait(1000)
    dungeon_7:get_sprite():set_animation("shining")
    wait(2000)
    local timer_sound = sol.timer.start(hero, 0, function()
      audio_manager:play_sound("misc/dungeon_shake")
      return 450
    end)
    timer_sound:set_suspended_with_map(false)
    local shake_config = {
        count = 256,
        amplitude = 2,
        speed = 90
    }
    camera:shake(shake_config, function()
      camera:start_manual()
      camera:set_position(camera_x + 72, camera_y)
    end)
    wait(2000)
    animation(dungeon_7:get_sprite(), "turning")
    timer_sound:stop()
    map:open_dungeon_7()
    wait(2000)
    audio_manager:play_sound("misc/secret2")
    local movement2 = sol.movement.create("straight")
    movement2:set_angle(math.pi)
    movement2:set_max_distance(72)
    movement2:set_speed(75)
    movement2:set_ignore_suspend(true)
    movement2:set_ignore_obstacles(true)
    movement(movement2, camera)
    map:set_cinematic_mode(false, options)
    camera:start_tracking(hero)
    map:init_music()
    game:set_value("dungeon_7_opened", true)
  end)
end