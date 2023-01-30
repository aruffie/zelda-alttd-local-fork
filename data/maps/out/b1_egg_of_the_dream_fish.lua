-- Variables
local map = ...
local game = map:get_game()
local hero = map:get_hero()

-- Include scripts
require("scripts/multi_events")
local travel_manager = require("scripts/maps/travel_manager")
local owl_manager = require("scripts/maps/owl_manager")
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
  if game:is_step_last("ghost_joined") 
    or game:is_step_last("ghost_saw_his_house")
    or game:is_step_last("ghost_house_visited")
    or game:is_step_last("marin_joined") then
        dungeon_2_1_A:set_enabled(false)
  end

end)

map:register_event("on_opening_transition_finished", function(map, destination)

  if destination == dungeon_2_2_A and game:is_step_last("marin_joined") then
    game:start_dialog("scripts.meta.map.companion_marin_dungeon_out", game:get_player_name())
  end

end)

-- Initialize the music of the map
function map:init_music()
  
  local x_hero, y_hero = hero:get_center_position()
  if y_hero < 384 then
    audio_manager:play_music("46_tal_tal_mountain_range")
  else
    audio_manager:play_music("10_overworld")
  end
end

-- Initializes Entities based on player's progress
function map:init_map_entities()
  
    -- Owl
  owl_6:set_enabled(false)
  -- Remove the big stone if you come from the secret cave
  if destination == stair_arrows_upgrade then
    secret_stone:set_enabled(false)
  end
  -- Egg
  self:set_egg_opened(false)

end

-- Set if the egg is opened or not.
function map:set_egg_opened(is_opened)
  
  if is_opened then
    egg_door:get_sprite():remove()
  end
  
end

-- Sensors events
function owl_6_sensor:on_activated()

  if game:get_value("owl_6") ~= true then
    owl_manager:appear(map, 6, function()
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
      dungeon_2_1_A:set_enabled(true)
    end)
  end

end


-- Handle boulders spawning depending on activated sensor.
for sensor in map:get_entities("sensor_activate_boulder_") do
  sensor:register_event("on_activated", function(sensor)
    spawner_boulder_1:start()
    spawner_boulder_2:start()
  end)
end
for sensor in map:get_entities("sensor_deactivate_boulder_") do
  sensor:register_event("on_activated", function(sensor)
    spawner_boulder_1:stop()
    spawner_boulder_2:stop()
  end)
end


-- Remove spawned boulders when too far of the mountain.
for spawner in map:get_entities("spawner_boulder_") do
  spawner:register_event("on_enemy_spawned", function(spawner, enemy)
    enemy:register_event("on_position_changed", function(enemy)
      local _, y, _ = enemy:get_position()
      if y > 500 then
        enemy:remove()
      end
    end)
  end)
end