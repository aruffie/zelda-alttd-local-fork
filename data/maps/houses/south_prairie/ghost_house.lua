-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")
local light_manager = require("scripts/maps/light_manager")

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  -- Entities
  map:init_map_entities()
  -- Light
  light_manager:init(map)
  
  -- Ghost
  ghost:set_enabled(false)

end)

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("51_house_by_the_bay")

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
  
  print("nok")
  if seashell_21 and game:get_value("ghost_quest_step") ~= "ghost_returned_to_tomb" then
    print("ok")
    seashell_21:set_enabled(false)
  end
  
end

-- NPCs events
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end

-- Sensors events

function sensor_1:on_activated()
  
  if game:get_value("ghost_quest_step") == "ghost_joined" then
    map:launch_cinematic_1()
  end
  
end


-- This is the cinematic in which the ghost visits his house
function map:launch_cinematic_1()
  
  map:start_coroutine(function()
    local options = {
      entities_ignore_suspend = {ghost, companion_ghost}
    }
    map:set_cinematic_mode(true, options)
    local x, y, layer = companion_ghost:get_position()
    ghost:set_position(x,y)
    ghost:set_enabled(true)
    companion_ghost:set_enabled(false)
    for i=1,3 do
      local position_entity = map:get_entity("position_ghost_" .. i)
      local movement1 = sol.movement.create("target")
      movement1:set_speed(32)
      movement1:set_target(position_entity)
      movement1:set_ignore_suspend(true)
      movement1:set_ignore_obstacles(true)
      movement(movement1, ghost)
      wait(2000)
    end
    dialog("maps.houses.south_prairie.ghost_house.ghost_1")
    local position_entity = map:get_entity("position_ghost_4")
    local movement2 = sol.movement.create("target")
    movement2:set_speed(64)
    movement2:set_target(position_entity)
    movement2:set_ignore_suspend(true)
    movement2:set_ignore_obstacles(true)
    movement2:start(ghost)
    wait(2000)
    dialog("maps.houses.south_prairie.ghost_house.ghost_2")
    hero:teleport("out/b4_south_prairie", "ghost_house_2_A")
    map:set_cinematic_mode(false)
    game:set_value("ghost_quest_step", "ghost_house_visited")
  end)

end

