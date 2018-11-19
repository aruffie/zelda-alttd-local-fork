-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local separator_manager = require("scripts/maps/separator_manager")
local treasure_manager = require("scripts/maps/treasure_manager")

-- Map events
function map:on_started(destination)

  -- Music
  map:init_music()
  -- Entities
  map:init_map_entities()
  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_golden_leaf_3")
  
end

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("32_kanalet_castle")

end

-- Initializes Entities based on player's progress
function map:init_map_entities()

  -- Switch 1
  if game:get_value("castle_door_is_open") then
    switch_1:set_activated(true)
  end
  
end

-- Switchs events
function switch_1:on_activated()
  
  if game:get_value("castle_door_is_open") == nil then
    game:set_value("castle_door_is_open", true)
    map:launch_cinematic_1()
  end
  
end

-- Treasures events
treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_3_", "pickable_golden_leaf_3")

-- Cinematics
-- This is the cinematic in which the hero open the main door of castle
function map:launch_cinematic_1()

  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {hero}
    }
    map:set_cinematic_mode(true, options)
    sol.audio.stop_music()
    local camera = map:get_camera()
    hero:set_direction(3)
    wait(1000)
    sol.audio.play_sound("castle_door")
    sol.audio.play_sound("shake")
    local shake_config = {
        count = 32,
        amplitude = 4,
        speed = 90
    }
    wait_for(camera.shake,camera,shake_config)
    dialog("maps.houses.kanalet_castle.door")
    map:set_cinematic_mode(false, options)
    map:init_music()
  end)

end

-- Separators
separator_manager:manage_map(map)
