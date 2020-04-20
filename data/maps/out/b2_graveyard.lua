-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
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

end)

-- Initializes Entities based on player's progress
function map:init_map_entities()
  
  ghost:set_enabled(false)

end

-- Initialize the music of the map
function map:init_music()
  
  audio_manager:play_music("10_overworld")

end

-- Sensors events

function sensor_1:on_activated()
  
  if game:is_step_last("ghost_house_visited") then
    map:launch_cinematic_1()
  end
  
end


-- This is the cinematic in which the ghost comes home
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
    local movement1 = sol.movement.create("target")
    movement1:set_speed(32)
    movement1:set_target(position_ghost)
    movement1:set_ignore_suspend(true)
    movement1:set_ignore_obstacles(true)
    movement(movement1, ghost)
    wait(2000)
    dialog("maps.out.graveyard.ghost_1")
    wait(2000)
    owl_manager:appear(map, 9, function()
      map:init_music()
    end)
    map:set_cinematic_mode(false)
    game:set_step_done("ghost_returned_to_tomb")
  end)

end


