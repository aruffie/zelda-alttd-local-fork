-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")


-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  -- Entities
  map:init_map_entities()
  -- Digging
  map:set_digging_allowed(true)
  -- Make areas invisible.
  mask_shrine_area_1:set_visible(false)
  mask_shrine_area_2:set_visible(false)

end)

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("10_overworld")

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
  
  dungeon_6_wall_1:set_enabled(false)
  dungeon_6_wall_2:set_enabled(false)
  if game:get_value("dungeon_6_opened") then
    map:open_dungeon_6()
  end

end

-- Dungeon 6 opening
function map:open_dungeon_6()

  dungeon_6:get_sprite():set_animation("opened")
  dungeon_6:set_traversable_by(true)
  dungeon_6_wall_1:set_enabled(true)
  dungeon_6_wall_2:set_enabled(true)

end

-- Doors events
function weak_door_1:on_opened()
  
  audio_manager:play_sound("misc/secret1")
  
end


-- NPCs events
function dungeon_6_lock:on_interaction()

  if not game:get_value("possession_face_key") then
    game:start_dialog("maps.out.mask_shrine.dungeon_6_lock")
  elseif not game:get_value("dungeon_6_opened") then
    map:launch_cinematic_1()
  end
  
end

-- Cinematics
-- This is the cinematic in which the hero open dungeon 6 with face key
function map:launch_cinematic_1()

  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {dungeon_6}
    }
    map:set_cinematic_mode(true, options)
    sol.audio.stop_music()
    audio_manager:play_sound("misc/chest_open")
    local camera = map:get_camera()
    local camera_x, camera_y = camera:get_position()
    local movement1 = sol.movement.create("straight")
    movement1:set_angle(math.pi)
    movement1:set_max_distance(20)
    movement1:set_speed(75)
    movement1:set_ignore_suspend(true)
    movement1:set_ignore_obstacles(true)
    movement(movement1, camera)
    wait(1000)
    local timer_sound = sol.timer.start(hero, 0, function()
      audio_manager:play_sound("misc/dungeon_shake")
      return 450
    end)
    timer_sound:set_suspended_with_map(false)
    local shake_config = {
        count = 88,
        amplitude = 2,
        speed = 90
    }
    camera:shake(shake_config, function()
      camera:start_manual()
      camera:set_position(camera_x - 20, camera_y)
    end)
    animation(dungeon_6:get_sprite(), "awakening")
    timer_sound:stop()
    map:open_dungeon_6()
    wait(2000)
    audio_manager:play_sound("misc/secret2")
    wait(2000)
    local movement2 = sol.movement.create("straight")
    movement2:set_angle(0)
    movement2:set_max_distance(20)
    movement2:set_speed(75)
    movement2:set_ignore_suspend(true)
    movement2:set_ignore_obstacles(true)
    movement(movement2, camera)
    map:set_cinematic_mode(false, options)
    camera:start_tracking(hero)
    map:init_music()
    game:set_value("dungeon_6_opened", true)
  end)

end