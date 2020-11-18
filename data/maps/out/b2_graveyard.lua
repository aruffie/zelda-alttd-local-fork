-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local owl_manager = require("scripts/maps/owl_manager")
local audio_manager = require("scripts/audio_manager")

-- Disable a ghini or giant ghini positioned on a grave, then wake him up when the hero touches the grave or its stairs.
local function initialize_graves()

  for grave in map:get_entities("grave_") do
    grave:set_size(32, 32) -- Workaround : No way to set the correct size to the bloc directly on the editor, so do it here.
    grave:set_origin(16, 29)
    for enemy in map:get_entities_by_type("enemy") do
      if (enemy:get_breed() == "ghini" or enemy:get_breed() == "ghini_giant") and enemy:overlaps(grave) then

        -- Create a custom entity on the grave entity to add a collision test on it.
        local x, y, layer = grave:get_position()
        local width, height = grave:get_size()
        local trigger = map:create_custom_entity({
          x = x,
          y = y,
          layer = layer,
          width = width,
          height = height,
          direction = 0
        })
        trigger:set_origin(width / 2.0, height - 3)
        trigger:set_position(grave:get_position()) -- Set the position again that have changed with the set_origin()

        -- Disable the ghini and wake him up when the grave is faced.
        enemy:set_enabled(false)
        trigger:add_collision_test("facing", function(trigger, entity)
          if entity:get_type() == "hero" then
            enemy:wake_up()
            trigger:remove()
          end
        end)
      end
    end
  end
end

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  -- Entities
  map:init_map_entities()
  -- Digging
  map:set_digging_allowed(true)

  -- Initialize grave connected to ghinis.
  initialize_graves()

  -- Make lower area invisible.
  graveyard_pit_1:set_visible(false)
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
  
  if game:get_value("ghost_quest_step") == "ghost_house_visited" then
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
    ghost:get_sprite():set_direction(1)
    ghost:get_sprite():set_animation("walking")
    local movement1 = sol.movement.create("target")
    movement1:set_speed(32)
    movement1:set_target(position_ghost)
    movement1:set_ignore_suspend(true)
    movement1:set_ignore_obstacles(true)
    movement(movement1, ghost)
    ghost:get_sprite():set_direction(3)
    ghost:get_sprite():set_animation("goodbye")
    wait(2000)
    dialog("maps.out.graveyard.ghost_1")
    wait(2000)
    ghost:set_enabled(false)
    if not game:get_value("possession_intrument_5") then
      owl_manager:appear(map, 9, function()
        map:init_music()
      end)
    else
      map:set_cinematic_mode(false, options)
    end
    game:set_value("ghost_quest_step", "ghost_returned_to_tomb")
  end)

end


