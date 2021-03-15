-- Variables
local map = ...
local game = map:get_game()
local is_boss_active = false

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local enemy_manager = require("scripts/maps/enemy_manager")

-- Map events
function map:on_started()

  -- Music
  map:init_music()
  -- Sideview
  map:set_sideview(true)

end

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("20_sidescrolling")

end

-- Start the boss
function sensor_1:on_activated()

  if is_boss_active == false then
    is_boss_active = true
    enemy_manager:launch_boss_if_not_dead(map)

    function boss:on_dying()
      game:start_dialog("maps.dungeons.7.boss_dying")
    end
  end
end

-- Remove the ladder when top reached.
function sensor_2:on_activated()

  if ladder_bottom:exists() then
    ladder_background:remove()
    ladder_top:remove()
    ladder_bottom:remove()
  end
end