-- Variables
local map = ...
local game = map:get_game()
local is_boss_active = false

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local enemy_manager = require("scripts/maps/enemy_manager")
local treasure_manager = require("scripts/maps/treasure_manager")

-- Map events
function map:on_started()

  -- Music
  map:init_music()
  -- Sideview
  map:set_sideview(true)
  -- Pickables
  treasure_manager:disappear_pickable(map, "heart_container")
  treasure_manager:appear_heart_container_if_boss_dead(map)
end

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("20_sidescrolling")

end

-- Start boss on separator taken.
function separator:on_activating(direction4)

  -- Start the boss if needed.
  if is_boss_active == false and not game:get_value("dungeon_" .. game:get_dungeon_index() .. "_boss") then
    is_boss_active = true
    enemy_manager:launch_boss_if_not_dead(map)

    -- Forbid to go back to the upper screen.
    hero:freeze()
    local movement = sol.movement.create("straight")
    movement:set_speed(40)
    movement:set_angle(math.pi * 1.5)
    movement:set_max_distance(24)
    movement:start(hero)

    function movement:on_finished()
      hero:unfreeze()
      local x, y = separator:get_position()
      local width, height = separator:get_size()
      map:create_wall({
        x = x,
        y = y,
        layer = hero:get_layer(),
        width = width,
        height = height,
        stops_hero = true
      })
    end
  end
end
