-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local separator_manager = require("scripts/maps/separator_manager")
local treasure_manager = require("scripts/maps/treasure_manager")
local door_manager = require("scripts/maps/door_manager")

-- Disable a darknut positioned on a darknut statue, and free him when the darknut statue is destroyed by a bomb.
local function initialize_darknut_statues()

  for statue in map:get_entities("darknut_statue_") do
    local darknut
    for enemy in map:get_entities_by_type("enemy") do
      if enemy:get_breed() == "darknut" and enemy:overlaps(statue) then
        enemy.is_enabled = false
        enemy:set_enabled(false)
        darknut = enemy

        -- Workaround : Avoid the darknut to be reenabled by the separator manager.
        enemy:register_event("on_enabled", function()
          if not enemy.is_enabled then
            enemy:set_enabled(false)
          end
        end)
      end
    end

    -- Destroy the statue on explosed and wake up the darknut if any.
    statue:add_collision_test("overlapping", function(statue, entity)
      if entity:get_type() == "explosion" then
        if darknut then
          darknut.is_enabled = true
          darknut:wake_up()
        end
        statue:get_sprite():set_animation("opened")
        statue:clear_collision_tests()
      end
    end)
  end
end

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  -- Doors
  door_manager:open_when_pot_break(map, "door_group_1_")
  door_manager:open_when_enemies_dead(map,  "enemy_group_3_",  "door_group_1_")
  initialize_darknut_statues()
  -- Enemies
  if game:get_value("golden_leaf_5") then
    enemy_group_3_1:remove()
    map:set_doors_open("door_group_1", true)
  end
  -- Pickables
  treasure_manager:disappear_pickable(map, "pickable_golden_leaf_4")
  treasure_manager:appear_pickable_when_enemies_dead(map, "enemy_group_2_", "pickable_golden_leaf_4")
  -- Separators
  separator_manager:init(map)
  
end)

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("32_kanalet_castle")

end

-- Sensors events
function close_door_sensor:on_activated()

  door_manager:close_if_enemies_not_dead(map, "enemy_group_3_", "door_group_1_")

end

