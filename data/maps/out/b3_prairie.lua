-- Variables
local map = ...
local game = map:get_game()
local tarin_chased_by_bees = false

-- Include scripts
require("scripts/multi_events")
local owl_manager = require("scripts/maps/owl_manager")
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
  -- Disable dungeon 3 teleporter when ghost is with the hero
  if game:is_step_last("ghost_joined") 
    or game:is_step_last("ghost_saw_his_house")
    or game:is_step_last("ghost_house_visited")
    or game:is_step_last("marin_joined") then
        dungeon_3_1_A:set_enabled(false)
  end

end)

map:register_event("on_opening_transition_finished", function(map, destination)

  if destination == dungeon_3_2_A and game:is_step_last("marin_joined") then
    game:start_dialog("scripts.meta.map.companion_marin_dungeon_out", game:get_player_name())
  end

end)

-- Initialize the music of the map
function map:init_music()
  
  if game:is_step_last("shield_obtained") then
    audio_manager:play_music("07_koholint_island")
  elseif tarin_chased_by_bees then
    audio_manager:play_music("39_bees")
  else
    audio_manager:play_music("10_overworld")
  end

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
  
  local item = game:get_item("magnifying_lens")
  local variant = item:get_variant()
 -- Owl
  owl_7:set_enabled(false)
  -- Travel
  travel_transporter:set_enabled(false)
  -- Statue pig
  if game:get_value("statue_pig_exploded") then
    statue_pig:get_sprite():set_animation("stopped")
    statue_pig:set_traversable_by(true)
  end
  dungeon_3_entrance:set_traversable_by(false)
  if game:is_step_done("dungeon_3_opened") then
    map:open_dungeon_3()
  end
  -- Tarin
  if not game:is_step_last("dungeon_3_completed") then
    tarin:set_enabled(false)
  end
  -- Honey and bees
  honey:set_enabled(false)
  if game:is_step_done("dungeon_3_completed") and variant > 5 then
    honey_entity:set_enabled(false)
    for bee in map:get_entities("bee") do
      bee:set_enabled(false)
    end
  end
  -- Owl slab
  if game:get_value("travel_1") then
    owl_slab:get_sprite():set_animation("activated")
  end
  -- Seashell's tree
  local seashell_tree_found = false
  collision_seashell:add_collision_test("facing", function(entity, other, entity_sprite, other_sprite)
    if other:get_type() == 'hero' and hero:get_state() == "custom" and hero:get_state_object():get_description()=="running" and seashell_tree_found == false and game:get_value("seashell_13") == nil then
      sol.timer.start(map, 250, function()
        seashell_13:set_enabled(true)
        local movement = sol.movement.create("jump")
        movement:set_speed(100)
        movement:set_distance(64)
        movement:set_direction8(0)
        movement:set_ignore_obstacles(true)
        movement:start(seashell_13, function()
            print ("finished! ", seashell_13:get_position())
          seashell_tree_found = true 
        end)
      end)
    end
  end)
  
end

-- Dungeon 3 opening
function map:open_dungeon_3()

  dungeon_3_entrance:get_sprite():set_animation("opened")
  dungeon_3_entrance:set_traversable_by(true)

end

-- Discussion with Tarin
function map:talk_to_tarin() 

  game:start_dialog("maps.out.prairie.tarin_1", game:get_player_name(), function(answer)
    if answer == 1 then
      map:launch_cinematic_2()
    else
      game:start_dialog("maps.out.prairie.tarin_2", game:get_player_name())
    end
  end)

end

-- Doors events
function weak_door_1:on_opened()
  
  audio_manager:play_sound("misc/secret1")
  
end

function weak_door_2:on_opened()
  
  audio_manager:play_sound("misc/secret1")

end

-- NPCs events
sign_start:register_event("on_interaction", function(npc)

  game:start_dialog("maps.out.south_prairie.surprise_3")
  game:set_value("wart_cave_start", true)

end)

function tarin:on_interaction()

  map:talk_to_tarin()

end

function dungeon_3_lock:on_interaction()

  if not game:is_step_done("dungeon_3_key_obtained") then
    game:start_dialog("maps.out.prairie.dungeon_3_lock")
  elseif game:is_step_last("dungeon_3_key_obtained") then
    map:launch_cinematic_1()
  end

end

-- Sensors events
function travel_sensor:on_activated()

  travel_manager:init(map, 1)

end

function owl_7_sensor:on_activated()

  if game:is_step_last("dungeon_3_completed") and game:get_value("owl_7") ~= true then
    owl_manager:appear(map, 7, function()
    map:init_music()
    end)
  end

end

function sensor_companion:on_activated()

  if map:get_game():is_step_last("ghost_joined") 
    or map:get_game():is_step_last("ghost_saw_his_house")
    or map:get_game():is_step_last("ghost_house_visited") then
        game:start_dialog("scripts.meta.map.companion_ghost_dungeon_in")
  elseif game:is_step_last("marin_joined") then
    game:start_dialog("scripts.meta.map.companion_marin_dungeon_in", game:get_player_name(), function()
      dungeon_3_1_A:set_enabled(true)
    end)
  end

end



-- Cinematics

-- This is the cinematic in which the hero open dungeon 3 with tail key
function map:launch_cinematic_1()

  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {dungeon_3_entrance}
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
    wait(1000)
    local timer_sound = sol.timer.start(hero, 0, function()
      audio_manager:play_sound("misc/dungeon_shake")
      return 450
    end)
    timer_sound:set_suspended_with_map(false)
    local shake_config = {
        count = 32,
        amplitude = 2,
        speed = 90
    }
    wait_for(camera.shake,camera,shake_config)
    timer_sound:stop()
    camera:start_manual()
    camera:set_position(camera_x, camera_y - 72)
    audio_manager:play_sound("misc/secret2")
    animation(dungeon_3_entrance:get_sprite(), "opening")
    map:open_dungeon_3()
    local movement2 = sol.movement.create("straight")
    movement2:set_angle(3 * math.pi / 2)
    movement2:set_max_distance(72)
    movement2:set_speed(75)
    movement2:set_ignore_suspend(true)
    movement2:set_ignore_obstacles(true)
    movement(movement2, camera)
    map:set_cinematic_mode(false, options)
    camera:start_tracking(hero)
    game:set_step_done("dungeon_3_opened")
    map:init_music()
  end)

end

-- This is the cinematic in which the hero collects honey.
function map:launch_cinematic_2()

  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, tarin, honey, tarin_invisible, bee_1, bee_2, bee_3, bee_4}
    }
    map:set_cinematic_mode(true, options)
    local camera = map:get_camera()
    camera:start_manual()
    local x_tarin, y_tarin, layer_tarin = tarin:get_position()
    local x_honey, y_honey, layer_honey = honey:get_position()
    tarin:get_sprite():set_animation("brandish")
    audio_manager:play_sound("items/fanfare_item_extended")
    local stick_entity = map:create_custom_entity({
    name = "brandish_baton",
    sprite = "entities/items",
    x = x_tarin,
    y = y_tarin- 32,
    width = 16,
    height = 16,
    layer = layer_tarin + 1,
    direction = 0
    })
    stick_entity:get_sprite():set_animation("magnifying_lens")
    stick_entity:get_sprite():set_direction(4)
    wait(1000)
    hero:set_animation("walking")
    hero:set_direction(3)
    local movement1 = sol.movement.create("target")
    movement1:set_speed(30)
    movement1:set_target(link_wait_tarin_place)
    movement1:set_ignore_suspend(true)
    movement(movement1, hero)
    hero:set_animation("stopped")
    hero:set_direction(1)
    wait(2000)
    sol.audio.stop_music()
    -- Tarin search honey
    tarin:get_sprite():set_animation("searching_honey")
    stick_entity:remove()
    audio_manager:play_sound("misc/beehive_poke1")
    for i=1,4 do
      wait(500 * i)
      if i == 2 then
          audio_manager:play_sound("misc/beehive_poke2")
      end
      audio_manager:play_sound("misc/beehive_bees")
      local bee = map:create_custom_entity({
        name = "bee_chase_" .. i,
        sprite = "entities/insects/bee",
        x = x_honey,
        y = y_honey,
        width = 16,
        height = 16,
        layer = layer_honey + 1,
        direction = 0
      })
    end
    wait(2500)
    tarin_chased_by_bees = true
    map:init_music()
    tarin:get_sprite():set_animation("run_bee")
    -- Tarin run
    local movement2 = sol.movement.create("circle")
    movement2:set_angle_speed(200)
    movement2:set_center(circle_center)
    movement2:set_radius(48)
    movement2:set_initial_angle(315)
    movement2:set_ignore_obstacles(true)
    movement2:set_ignore_suspend(true)
    movement2:start(tarin_invisible)
    function movement2:on_position_changed()
      local x_tarin,y_tarin = tarin_invisible:get_position()
      local circle_angle = circle_center:get_angle(tarin_invisible)
      local movement_angle = circle_angle + math.pi/2
      movement_angle = math.deg(movement_angle)
      local direction = math.floor((movement_angle + 45) / 90)
      direction = direction % 4
      tarin:set_position(x_tarin, y_tarin)
      tarin:get_sprite():set_direction(direction)
    end
    for bee in map:get_entities("bee_chase") do
      local movement_bee = sol.movement.create("target")
      local bee_sprite = bee:get_sprite()
      movement_bee:set_target(tarin, math.random(-16, 16), math.random(-16, 16))
      movement_bee:set_speed(150)
      movement_bee:set_ignore_obstacles(true)
      movement_bee:set_ignore_suspend(true)
      movement_bee:start(bee)
      function movement_bee:on_position_changed()
        local circle_angle = circle_center:get_angle(tarin_invisible)
        local movement_angle = circle_angle + math.pi/2
        movement_angle = math.deg(movement_angle)
        local direction = math.floor((movement_angle + 45) / 90)
        direction = direction % 4
        bee_sprite:set_direction(direction)
      end
    end
    wait(6000)
    -- Tarin leave map
    tarin_invisible:get_movement():stop()
    local movement_target = sol.movement.create("target")
    movement_target:set_speed(120)
    movement_target:set_ignore_suspend(true)
    movement_target:set_target(tarin_leave_map)
    function movement_target:on_position_changed()
      local x_tarin, y_tarin= tarin_invisible:get_position()
      local direction = movement_target:get_direction4()
      tarin:set_position(x_tarin, y_tarin)
      tarin:get_sprite():set_direction(direction)
    end
    movement(movement_target, tarin_invisible)
    tarin_invisible:set_enabled(false)
    tarin:set_enabled(false)
    for bee in map:get_entities("bee_chase") do
      bee:set_enabled(false)
    end
    wait(500)
    sol.audio.stop_music()
    wait(1000)
    honey:set_enabled(true)
    honey_entity:set_enabled(false)
    local movement3 = sol.movement.create("jump")
    movement3:set_speed(100)
    movement3:set_distance(32)
    movement3:set_direction8(6)
    movement3:set_ignore_obstacles(true)
    movement3:set_ignore_suspend(true)
    movement(movement3, honey)
    audio_manager:play_sound("misc/beehive_fall")
    tarin_chased_by_bees = false
    map:init_music()
    local movement_camera = sol.movement.create("target")
    local x,y = camera:get_position_to_track(hero)
    movement_camera:set_speed(120)
    movement_camera:set_target(x,y)
    movement_camera:set_ignore_obstacles(true)
    movement_camera:set_ignore_suspend(true)
    movement(movement_camera, camera)
    camera:start_tracking(hero)
    game:set_step_done("tarin_bee_event_over")
    map:set_cinematic_mode(false, options)
  end)
  
end