-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
local owl_manager = require("scripts/maps/owl_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events
function map:on_started(destination)

  -- Music
  map:init_music()
  -- Entities
  map:init_map_entities()
  -- Digging
  map:set_digging_allowed(true)
  -- Shore
  map:init_shore()

end

-- Initialize the music of the map
function map:init_music()

  if game:get_value("main_quest_step") == 3  then
    audio_manager:play_music("07_koholint_island")
  else
    audio_manager:play_music("10_overworld")
  end

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
  
  owl_1:set_enabled(false)
  owl_4:set_enabled(false)
  if sword ~= nil then
    sword:get_sprite():set_direction(4)
    sword:get_sprite():set_ignore_suspend(true)
  end
  dungeon_1_entrance:set_traversable_by(false)
  dungeon_1_entrance:set_traversable_by('camera', true)
  if game:get_value("main_quest_step") > 6 then
    map:open_dungeon_1()
  end
  -- Seashell's tree
  local seashell_tree_found = false
  collision_seashell:add_collision_test("facing", function(entity, other, entity_sprite, other_sprite)
    if other:get_type() == 'hero' and hero:get_state() == "custom" and hero:get_state_object():get_description()=="running" and seashell_tree_found == false and game:get_value("seashell_14") == nil then

      sol.timer.start(map, 250, function()
        seashell_14:set_enabled(true)
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

-- Initialize shore
function map:init_shore()
  
  sol.timer.start(map, 5000, function()
    local x,y,layer = hero:get_position()
    if y > 500 then
      audio_manager:play_sound("misc/shore")
    end  
    return true
  end)
  
end  

-- Dungeon 1 opening
function map:open_dungeon_1()

  dungeon_1_entrance:get_sprite():set_animation("opened")
  dungeon_1_entrance:set_traversable_by(true)

end

-- Obtaining sword
function map:on_obtaining_treasure(treasure_item, treasure_variant, treasure_savegame_variable)

  if treasure_item:get_name() == "sword" then
    map:launch_cinematic_1()
  end

end

-- NPCs events
function dungeon_1_lock:on_interaction()

  if game:get_value("main_quest_step") < 6 then
      game:start_dialog("maps.out.south_mabe_village.dungeon_1_lock")
  elseif game:get_value("main_quest_step") == 6 then
    map:launch_cinematic_2()
  end
  
end

-- Sensors events
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

-- Cinematics
-- This is the cinematic in which the hero retrieves his sword
function map:launch_cinematic_1()
  
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero}
    }
    map:set_cinematic_mode(true, options)
    sol.audio.stop_music()
    audio_manager:play_sound("items/get_sword")
    animation(hero,"pulling_sword")
    hero:get_sprite():set_animation("pulling_sword_wait")
    wait(3000)
    local map = game:get_map()
    dialog("_treasure.sword.1")
    audio_manager:play_music("09_beginning_of_the_journey")
    wait(4400)
    local num_enemies = 0
    for enemy in map:get_entities_by_type("enemy") do
      if enemy:get_distance(hero) < 32 and not string.match(enemy:get_breed(), "projectiles")  then
        num_enemies = num_enemies + 1
        enemy.symbol = enemy:create_symbol_exclamation()
      end
    end
    if num_enemies > 0 then
      audio_manager:play_sound("menus/menu_select")
    end
    wait(1000)
    map:remove_entities("brandish")
    for enemy in map:get_entities_by_type("enemy") do
      if enemy:get_distance(hero) < 32 and not string.match(enemy:get_breed(), "projectiles") then
        enemy.symbol:remove()
        enemy:set_life(0)
      end
    end
    if num_enemies > 0 then
      audio_manager:play_sound("enemies/enemy_die")
    end
    animation(hero, "spin_attack")
    map:set_cinematic_mode(false, options)
    game:set_value("main_quest_step", 4)
    audio_manager:play_music("10_overworld")
  end)

end

-- This is the cinematic in which the hero open dungeon 1 with tail key
function map:launch_cinematic_2()

  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {dungeon_1_entrance}
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
    animation(dungeon_1_entrance:get_sprite(), "opening")
    map:open_dungeon_1()
    local movement2 = sol.movement.create("straight")
    movement2:set_angle(3 * math.pi / 2)
    movement2:set_max_distance(72)
    movement2:set_speed(75)
    movement2:set_ignore_suspend(true)
    movement2:set_ignore_obstacles(true)
    movement(movement2, camera)
    map:set_cinematic_mode(false, options)
    camera:start_tracking(hero)
    game:set_value("main_quest_step", 7)
    map:init_music()
  end)

end
