-- Variables
local map = ...
local game = map:get_game()
local hero = map:get_hero()

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
 -- Disable dungeon 2 teleporter when ghost is with the hero
  if map:get_game():is_step_last("ghost_joined") 
    or map:get_game():is_step_last("ghost_saw_his_house")
    or map:get_game():is_step_last("ghost_house_visited") then
      dungeon_4_1_A:set_enabled(false)
  end
 --Jumping if coming from the Bird key cave
  if destination == cave_c1_bird_cave_key_hole then
    hero:start_jumping(6,48,true)
  end

end)

map:register_event("on_finished", function(map, destination)
    
  if game:get_value("possession_instrument_4") and game:is_step_last("dungeon_4_finished") then
    game:set_step_done("ghost_joined")
  end

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
  
  -- Father and hibiscus
  local item = game:get_item("magnifying_lens")
  local variant = item:get_variant()
  if not game:is_step_done("dungeon_3_completed") or variant >= 8  then
    father:set_enabled(false)
    hibiscus:set_enabled(false)
  end
  father:get_sprite():set_animation("calling")
  hibiscus:get_sprite():set_animation("magnifying_lens")
  hibiscus:get_sprite():set_direction(7)
  -- Waterfall
  if game:is_step_done("dungeon_4_opened") then
    map:open_dungeon_4()
  end
  
end

-- Discussion with Father 1
function map:talk_to_father() 

 local item = game:get_item("magnifying_lens")
 local variant = item:get_variant()
 father:get_sprite():set_animation("sitting")
 if variant == 7 then
   game:start_dialog("maps.out.mambos_cave.father_1", function(answer)
    if answer == 1 then
      game:start_dialog("maps.out.mambos_cave.father_3", function()
        map:launch_cinematic_1()
      end)
    else
      game:start_dialog("maps.out.mambos_cave.father_2", function()
        father:get_sprite():set_animation("calling")
      end)
    end
   end)
 elseif variant == 8 then
    game:start_dialog("maps.out.mambos_cave.father_5", function()
      father:get_sprite():set_animation("eating")
    end)
 else
   game:start_dialog("maps.out.mambos_cave.father_6", function(answer)
    game:start_dialog("maps.out.mambos_cave.father_2", function()
      father:get_sprite():set_animation("calling")
    end)
   end)
  end

end

function map:remove_water(step)

  if step > 9 then
    return
  end
  sol.timer.start(map, 1000, function()
    for tile in map:get_entities("waterfall_" .. step) do
      tile:remove()
    end
    step = step + 1
    map:remove_water(step)
  end)

end

-- Dungeon 4 opening
function map:open_dungeon_4()

  for tile in map:get_entities("waterfall") do
    tile:remove()
  end

end

-- NPCs events
function father:on_interaction()

  map:talk_to_father()

end

-- NPCs events
function dungeon_4_lock:on_interaction()

  if not game:is_step_done("dungeon_4_key_obtained") then
    game:start_dialog("maps.out.mambos_cave.dungeon_4_lock")
  elseif game:is_step_last("dungeon_4_key_obtained") then
    map:launch_cinematic_2()
  end
  
end

-- Sensor events
function sensor_companion:on_activated()

  if map:get_game():is_step_last("ghost_joined") 
    or map:get_game():is_step_last("ghost_saw_his_house")
    or map:get_game():is_step_last("ghost_house_visited") then
        game:start_dialog("scripts.meta.map.companion_ghost_dungeon_in")
  end

end

-- Cinematics
-- This is the cinematic in which Father quadruplet eat pineapple
function map:launch_cinematic_1()
  
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, father}
    }
    map:set_cinematic_mode(true, options)
    father:get_sprite():set_animation("eating")
    wait(5000)
    father:get_sprite():set_animation("sitting")
    dialog("maps.out.mambos_cave.father_4")
    hibiscus:set_enabled(false)
    wait_for(hero.start_treasure, hero, "magnifying_lens", 8, "magnifying_lens_8")
    father:get_sprite():set_animation("eating")
    map:set_cinematic_mode(false, options)
  end)

end

-- This is the cinematic in which the hero open dungeon 4 with angler key
function map:launch_cinematic_2()
  
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {}
    }
    map:set_cinematic_mode(true, options)
    sol.audio.stop_music()
    audio_manager:play_sound("misc/chest_open")
    local camera = map:get_camera()
    local camera_x, camera_y = camera:get_position()
    local movement1 = sol.movement.create("straight")
    movement1:set_angle(math.pi / 2)
    movement1:set_max_distance(72)
    movement1:set_speed(75)
    movement1:set_ignore_suspend(true)
    movement1:set_ignore_obstacles(true)
    movement(movement1, camera)
    wait(2000)
    map:remove_water(1)
    local timer_sound = sol.timer.start(hero, 0, function()
      audio_manager:play_sound("misc/dungeon_shake")
      return 450
    end)
    timer_sound:set_suspended_with_map(false)
    local shake_config = {
        count = 320,
        amplitude = 2,
        speed = 90
    }
    wait_for(camera.shake, camera, shake_config)
    camera:start_manual()
    camera:set_position(camera_x, camera_y - 72)
    timer_sound:stop()
    wait(1000)
    audio_manager:play_sound("misc/secret2")
    wait(1000)
    map:init_music()
    map:open_dungeon_4()
    local movement2 = sol.movement.create("straight")
    movement2:set_angle(3 * math.pi / 2)
    movement2:set_max_distance(72)
    movement2:set_speed(75)
    movement2:set_ignore_suspend(true)
    movement2:set_ignore_obstacles(true)
    movement(movement2, camera)
    map:set_cinematic_mode(false, options)
    camera:start_tracking(hero)
    game:set_step_done("dungeon_4_opened")
  end)

end

