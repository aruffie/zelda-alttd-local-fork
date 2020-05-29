-- Variables
local travel_manager = {}
local positions_info = {
  [1] = {
        map_id = "out/b3_prairie",
        sensor_name = "travel_sensor",
        destination_name = "travel_destination",
        transporter_name = "travel_transporter",
        slab_name = "owl_slab",
        savegame = "travel_1"
  },
  [2] = {
        map_id = "out/a1_west_mt_tamaranch",
        sensor_name = "travel_sensor",
        destination_name = "travel_destination",
        transporter_name = "travel_transporter",
        slab_name = "owl_slab",
        savegame = "travel_2"
  },
  [3] = {
        map_id = "out/d1_east_mt_tamaranch",
        sensor_name = "travel_sensor",
        destination_name = "travel_destination",
        transporter_name = "travel_transporter",
        slab_name = "owl_slab",
        savegame = "travel_3"
  },
  [4] = {
        map_id = "out/d4_yarna_desert",
        sensor_name = "travel_sensor",
        destination_name = "travel_destination",
        transporter_name = "travel_transporter",
        slab_name = "owl_slab",
        savegame = "travel_4"
  },
  [5] = {
        map_id = "out/a1_west_mt_tamaranch",
        sensor_name = "travel_sensor_2",
        destination_name = "travel_destination_2",
        transporter_name = "travel_transporter_2",
        slab_name = "owl_slab_2",
        savegame = "travel_5"
  },
}

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local mode_7_manager = require("scripts/mode_7")

function travel_manager:init(map, from_id)
  
  local game = map:get_game()
  local savegame = positions_info[from_id]['savegame']
  if not game:get_value(savegame) then
    travel_manager:launch_cinematic(map, from_id)
  else
    travel_manager:launch_owl(map, from_id)
  end
  
end

function travel_manager:launch_cinematic(map, from_id)
    
  local game = map:get_game()
  local hero = map:get_hero()
  local info = positions_info[from_id]
  -- Transporter
  local transporter = map:get_entity(info.transporter_name)
  -- Owl slab
  local owl_slab = map:get_entity(info.slab_name)
  assert(transporter ~= nil)
  assert(owl_slab ~= nil)
  sol.main.start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero, transporter, owl_slab}
    }
    map:set_cinematic_mode(true, options)
    wait(2000)
    audio_manager:play_sound("misc/secret1")
    owl_slab:get_sprite():set_animation("activated")  
    travel_manager:launch_owl(map, from_id)
  end)    
    
end 

function travel_manager:launch_owl(map, from_id)

  local game = map:get_game()
  local info = positions_info[from_id]
  local savegame = info.savegame
  game:set_value(savegame, 1)
  local transporter = map:get_entity(info.transporter_name)
  transporter:set_enabled(false)
  local i = from_id + 1
  if i > #positions_info then
    i = 1
  end
  while game:get_value(positions_info[i].savegame) == nil do
    i = i + 1
    if i > #positions_info then
      i = 1
    end
  end
  local to_id = i
  if from_id ~= to_id then
    travel_manager:launch_owl_step_1(map, from_id, to_id)
  end

end


function travel_manager:launch_owl_step_1(map, from_id, to_id)

  local game = map:get_game()
  local hero = map:get_hero()
  local info = positions_info[from_id]
  -- Hero
  local x_hero,y_hero = hero:get_position()
  hero:get_sprite():set_direction(3)
  y_hero = y_hero - 16
  -- Transporter
  local transporter = map:get_entity(info.transporter_name)
  local direction4 = transporter:get_direction4_to(hero)
  transporter:get_sprite():set_animation("walking")
  transporter:get_sprite():set_direction(direction4)
  transporter:set_enabled(true)
  -- Owl slab
  local owl_slab = map:get_entity(info.slab_name)
  sol.main.start_coroutine(function() -- start a game coroutine since we will change map in between
    local options = {
      entities_ignore_suspend = {hero, transporter, owl_slab}
    }
    map:set_cinematic_mode(true, options)
    -- First step
    local movement1 = sol.movement.create("target")
    movement1:set_speed(150)
    movement1:set_ignore_obstacles(true)
    movement1:set_ignore_suspend(true)
    movement1:set_target(x_hero, y_hero - 16)
    movement(movement1, transporter)
    hero:set_enabled(false)
    local x_transporter, y_transporter, layer_transporter = transporter:get_position()
    local flying_hero = map:create_custom_entity({
      sprite = "hero/tunic1",
      x = x_transporter,
      y = y_transporter + 16,
      width = 24,
      height = 24,
      layer = layer_transporter,
      direction = 0
    })
    -- Second step
    flying_hero:get_sprite():set_animation("flying")
    flying_hero:get_sprite():set_direction(3)
    if not game:get_value("travel_first_time") then
      wait(1000)
      dialog("scripts.meta.map.owl_travel_first_time_starts")
    end
    local movement2 = sol.movement.create("straight")
    movement2:set_speed(100)
    movement2:set_angle(math.pi / 2)
    movement2:set_max_distance(128)
    movement2:set_ignore_obstacles(true)
    movement2:set_ignore_suspend(true)
    function movement2:on_position_changed()
      local x_transporter, y_transporter, layer_transporter = transporter:get_position()
      y_transporter = y_transporter + 16
      flying_hero:set_position(x_transporter, y_transporter, layer_transporter)
    end
    movement(movement2, transporter)
    -- Mode 7
    travel_manager:launch_owl_step_2(map, from_id, to_id)
    local new_map = wait_for(map.wait_on_next_map_opening_transition_finished, map)
    -- We are on new map, 
    travel_manager:launch_step_3(new_map, from_id, to_id)
  end, game) -- end start coroutine, game arg is important

end

function travel_manager:launch_owl_step_2(map, from_id, to_id)

  local game = map:get_game()
  local hero = map:get_hero()
  local from_info = positions_info[from_id]
  local to_info = positions_info[to_id]
  local map_id = to_info.map_id
  local destination_name = to_info.destination_name
  local entity = map:get_entity(from_info.sensor_name)
  mode_7_manager:teleport(game, entity, map_id, destination_name)
  
end

function travel_manager:launch_step_3(map, from_id, to_id)

  local game = map:get_game()
  local hero = map:get_hero()
  local to_info = positions_info[to_id]
  -- Hero
  local x_hero,y_hero = hero:get_position()
  hero:get_sprite():set_direction(3)
  hero:set_enabled(false)
  -- Transporter
  local transporter = map:get_entity(to_info.transporter_name)
  transporter:set_enabled(true)
  local direction4 = transporter:get_direction4_to(hero)
  transporter:get_sprite():set_animation("walking")
  transporter:get_sprite():set_direction(direction4)
  local x_transporter,y_transporter, layer_transporter = transporter:get_position()
  transporter:set_position(x_hero, y_hero - 128)
  -- Owl slab
  local owl_slab = map:get_entity(to_info.slab_name)
  local flying_hero = map:create_custom_entity({
    sprite = "hero/tunic1",
    x = x_hero,
    y = y_transporter + 16,
    width = 24,
    height = 24,
    layer = layer_transporter,
    direction = 0
  })
  flying_hero:get_sprite():set_animation("flying")
  flying_hero:get_sprite():set_direction(3)
  local options = {
    entities_ignore_suspend = {hero, transporter, owl_slab}
  }
  map:set_cinematic_mode(true, options)
  sol.main.start_coroutine(function() -- start a game coroutine since we will change map in between
    -- First step
    local movement1 = sol.movement.create("target")
    movement1:set_speed(100)
    movement1:set_target(x_hero, y_hero - 16)
    movement1:set_ignore_obstacles(true)
    movement1:set_ignore_suspend(true)
    function movement1:on_position_changed()
      local x_transporter, y_transporter, layer_transporter = transporter:get_position()
      y_transporter = y_transporter + 16
      flying_hero:set_position(x_transporter, y_transporter, layer_transporter)
    end
    movement(movement1, transporter)
    if not game:get_value("travel_first_time") then
      wait(1000)
      dialog("scripts.meta.map.owl_travel_first_time_done")
      game:set_value("travel_first_time", true)
    end
    hero:set_enabled(true)
    flying_hero:remove()
    -- Second step
    local direction4 = transporter:get_direction4_to(x_transporter, y_transporter)
    transporter:get_sprite():set_animation("walking")
    transporter:get_sprite():set_direction(direction4)
    local movement2 = sol.movement.create("target")
    movement2:set_speed(100)
    movement2:set_target(x_transporter, y_transporter)
    movement2:set_ignore_obstacles(true)
    movement2:set_ignore_suspend(true)
    movement(movement2, transporter)
    transporter:set_enabled(false)
    map:set_cinematic_mode(false)
  end, game)

end


return travel_manager