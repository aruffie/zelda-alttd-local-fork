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
  if game:is_step_done("dungeon_3_completed") and variant < 5 then
    honey:set_enabled(false)
    for bee in map:get_entities("bee") do
        bee:set_enabled(false)
    end
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
      map:tarin_search_honey()
    else
      game:start_dialog("maps.out.prairie.tarin_2", game:get_player_name())
    end
  end)

end

-- Tarin search honey
function map:tarin_search_honey()
  
  local camera = map:get_camera()
  camera:start_manual()
  local x_tarin, y_tarin, layer_tarin = tarin:get_position()
  local x_honey, y_honey, layer_honey = honey:get_position()
  hero:freeze()
  game:set_hud_enabled(false)
  game:set_pause_allowed(false)
  local tarin_sprite = tarin:get_sprite()
  tarin_sprite:set_ignore_suspend(true)
  tarin_sprite:set_animation("brandish")
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
  sol.timer.start(map, 1000, function()
    hero:set_animation("walking")
    hero:set_direction(3)
    local movement = sol.movement.create("target")
    movement:set_speed(30)
    movement:set_target(link_wait_tarin_place)
    movement:start(hero)
    function movement:on_finished()
      hero:set_animation("stopped")
      hero:set_direction(1)
    end
  end)
  sol.timer.start(map, 2000, function()
    sol.audio.stop_music()
    tarin_sprite:set_animation("searching_honey")
    stick_entity:remove()
    audio_manager:play_sound("beehive_poke")
    for i=1,4 do
      sol.timer.start(map, 500 * i, function()
          if i == 2 then
              audio_manager:play_sound("beehive_poke")
          end
          audio_manager:play_sound("beehive_bees")
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
      end)
    end
    sol.timer.start(map, 2500, function()
        tarin_chased_by_bees = true
        map:init_music()
        tarin_sprite:set_animation("run_bee")
        map:tarin_run()
    end)
    sol.timer.start(map, 7000, function()
        tarin_chased_by_bees = true
        map:init_music()
        tarin_sprite:set_animation("run_bee")
        map:tarin_leave_map()
    end)
  end)

end

-- Tarin run
function map:tarin_run()

  local tarin_sprite = tarin:get_sprite()
  local movement = sol.movement.create("circle")
  movement:set_angle_speed(200)
  movement:set_center(circle_center)
  movement:set_radius(48)
  movement:set_initial_angle(315)
  movement:set_ignore_obstacles(true)
  movement:start(tarin_invisible)
  function movement:on_position_changed()
    local x_tarin,y_tarin= tarin_invisible:get_position()
    local circle_angle = circle_center:get_angle(tarin_invisible)
    local movement_angle = circle_angle + math.pi/2
    movement_angle = math.deg(movement_angle)
    local direction = math.floor((movement_angle + 45) / 90)
    direction = direction % 4
    tarin:set_position(x_tarin, y_tarin)
    tarin_sprite:set_direction(direction)
  end
  for bee in map:get_entities("bee_chase") do
    local movement_bee = sol.movement.create("target")
    local bee_sprite = bee:get_sprite()
    movement_bee:set_target(tarin, math.random(-16, 16), math.random(-16, 16))
    movement_bee:set_speed(150)
    movement_bee:set_ignore_obstacles(true)
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

end

-- Tarin leave map
function map:tarin_leave_map()
  
  tarin_invisible:get_movement():stop()
  local camera = map:get_camera()
  local tarin_sprite = tarin:get_sprite()
  local movement_target = sol.movement.create("target")
  movement_target:set_speed(120)
  movement_target:set_target(tarin_leave_map)
  movement_target:start(tarin_invisible)
  function movement_target:on_position_changed()
    local x_tarin,y_tarin= tarin_invisible:get_position()
    local direction = movement_target:get_direction4()
    tarin:set_position(x_tarin, y_tarin)
    tarin_sprite:set_direction(direction)
  end
  function movement_target:on_finished()
    tarin_invisible:set_enabled(false)
    tarin:set_enabled(false)
    for bee in map:get_entities("bee_chase") do
      bee:set_enabled(false)
    end
    sol.timer.start(map, 2500, function()
      sol.audio.stop_music()
      local movement = sol.movement.create("jump")
      movement:set_speed(100)
      movement:set_distance(32)
      movement:set_direction8(6)
      movement:set_ignore_obstacles(true)
      movement:start(honey)
      game:set_step_done("tarin_bee_event_over")
      audio_manager:play_sound("beehive_fall")
      hero:unfreeze()
      game:set_hud_enabled(true)
      game:set_pause_allowed(false)
      tarin_chased_by_bees = false
      map:init_music()
      hero:unfreeze()
      game:set_hud_enabled(true)
      game:set_pause_allowed(true)
      tarin_chased_by_bees = false
      map:init_music()
      local movement_camera = sol.movement.create("target")
      local x,y = camera:get_position_to_track(hero)
      movement_camera:set_speed(120)
      movement_camera:set_target(x,y)
      movement_camera:start(camera)
      function movement_camera:on_finished()
        camera:start_tracking(hero)
      end
    end)
  end

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
  elseif game:is_last_step("dungeon_3_key_obtained") then
    sol.audio.stop_music()
    hero:freeze()
    sol.timer.start(map, 1000, function() 
      audio_manager:play_sound("shake")
      local camera = map:get_camera()
      local shake_config = {
          count = 32,
          amplitude = 2,
          speed = 90,
      }
      camera:shake(shake_config, function()
        audio_manager:play_sound("misc/secret2")
        local sprite = dungeon_3_entrance:get_sprite()
        sprite:set_animation("opening")
        sol.timer.start(map, 800, function() 
          map:open_dungeon_3()
          hero:unfreeze()
          map:init_music()
        end)
      end)
      game:set_step_done("dungeon_3_opened")
    end)
  end

end

-- Obtaining slim key
function map:on_obtaining_treasure(treasure_item, treasure_variant, treasure_savegame_variable)

  if treasure_item:get_name() == "slim_key" then
    game:set_step_done("dungeon_3_key_obtained")
  end

end

-- Sensors events
function travel_sensor:on_activated()

    travel_manager:init(map, 1)

end

function owl_7_sensor:on_activated()

  if game:is_step_last("dungeon_3_completed")  and game:get_value("owl_7") ~= true then
    owl_manager:appear(map, 7, function()
    map:init_music()
    end)
  end

end

