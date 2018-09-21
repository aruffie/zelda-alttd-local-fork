-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
local owl_manager = require("scripts/maps/owl_manager")

-- Initialize the music of the map
function map:init_music()

  if game:get_value("main_quest_step") == 3  then
    sol.audio.play_music("maps/out/sword_search")
  else
    sol.audio.play_music("maps/out/overworld")
  end

end

-- Map events
function map:on_started(destination)

  map:init_music()
  -- Digging
  map:set_digging_allowed(true)
  owl_1:set_enabled(false)
  owl_4:set_enabled(false)
  if sword ~= nil then
    sword:get_sprite():set_direction(4)
  end
  dungeon_1_entrance:set_traversable_by(false)
  if game:get_value("main_quest_step") > 6 then
    map:open_dungeon_1()
  end
  -- Seashell's tree
  local seashell_tree_found = false
  collision_seashell:add_collision_test("facing", function(entity, other, entity_sprite, other_sprite)
    if other:get_type() == 'hero' and hero:get_state() == "running" and seashell_tree_found == false and game:get_value("seashell_14") == nil then
      sol.timer.start(map, 250, function()
        movement = sol.movement.create("jump")
        movement:set_speed(100)
        movement:set_distance(64)
        movement:set_direction8(0)
        movement:set_ignore_obstacles(true)
        movement:start(seashell_14, function()
          seashell_tree_found = true 
        end)
      end)
    end
  end)

end

function map:on_obtaining_treasure(treasure_item, treasure_variant, treasure_savegame_variable)

  if treasure_item:get_name() == "sword" then
    map:launch_cinematic_1()
  end

end
-- Sensor events
function owl_1_sensor:on_activated()

  if game:get_value("owl_1") == true then
    map:init_music()
  else
    owl_manager:appear(map, 1, function()
    map:init_music()
    end)
  end

end

function owl_4_sensor:on_activated()

  if game:get_value("main_quest_step") == 8  and game:get_value("owl_4") ~= true then
    owl_manager:appear(map, 4, function()
    map:init_music()
    end)
  end

end

-- NPC events
function dungeon_1_lock:on_interaction()

  if game:get_value("main_quest_step") < 6 then
      game:start_dialog("maps.out.south_mabe_village.dungeon_1_lock")
  elseif game:get_value("main_quest_step") == 6 then
    map:launch_cinematic_2()
  end
end

-- Others functions
function map:open_dungeon_1()

  dungeon_1_entrance:get_sprite():set_animation("opened")
  dungeon_1_entrance:set_traversable_by(true)

end

-- Cinematics
-- This is the cinematic in which the hero retrieves his sword
function map:launch_cinematic_1()
  
  -- Init and launch cinematic mode
  local options = {
    entities_ignore_suspend = {hero}
  }
  map:set_cinematic_mode(true, options)
  hero:set_animation("pulling_sword", function() 
    hero:set_animation("pulling_sword_wait")
  end)
  sol.audio.stop_music()
  sol.audio.play_sound("treasure_sword")
  local timer = sol.timer.start(3000, function()
      local map = game:get_map()
      game:start_dialog("_treasure.sword.1", function()
        sol.audio.play_music("maps/out/let_the_journey_begin")
        local timerspin = sol.timer.start(5400, function() 
          map:remove_entities("brandish")
          hero:set_animation("spin_attack", function() 
            hero:unfreeze()
            map:set_cinematic_mode(false, options)
            game:set_value("main_quest_step", 4)
            hero:get_sprite():set_ignore_suspend(false)
            local timermusic = sol.timer.start(300, function()
              sol.audio.play_music("maps/out/overworld")
            end)
            timermusic:set_suspended_with_map(false)
          end)
       end)
       timerspin:set_suspended_with_map(false)
    end)
  end)
  timer:set_suspended_with_map(false)

end

-- This is the cinematic in which the hero open dungeon 1 with tail key
function map:launch_cinematic_2()

  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {dungeon_1_entrance}
    }
    map:set_cinematic_mode(true, options)
    sol.audio.stop_music()
    local camera = map:get_camera()
    local camera_x, camera_y = camera:get_position()
    local movement1 = sol.movement.create("straight")
    movement1:set_angle(math.pi / 2)
    movement1:set_max_distance(72)
    movement1:set_speed(75)
    movement1:set_ignore_suspend(true)
    movement(movement1, camera)
    wait(1000)
    sol.audio.play_sound("shake")
    local shake_config = {
        count = 32,
        amplitude = 4,
        speed = 90
    }
    wait_for(camera.shake,camera,shake_config)
    camera:start_manual()
    camera:set_position(camera_x, camera_y - 72)
    sol.audio.play_sound("secret_2")
    dungeon_1_entrance:get_sprite():set_animation("opening")
    wait(2000)
    map:open_dungeon_1()
    local movement2 = sol.movement.create("straight")
    movement2:set_angle(3 * math.pi / 2)
    movement2:set_max_distance(72)
    movement2:set_speed(75)
    movement2:set_ignore_suspend(true)
    movement(movement2, camera)
    map:set_cinematic_mode(false, options)
    camera:start_tracking(hero)
    game:set_value("main_quest_step", 7)
    map:init_music()
  end)

end
