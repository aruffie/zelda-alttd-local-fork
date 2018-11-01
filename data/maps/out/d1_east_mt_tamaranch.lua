-- Variables
local map = ...
local game = map:get_game()
local hero = map:get_hero()

-- Include scripts
local travel_manager = require("scripts/maps/travel_manager")

-- Map events
function map:on_started()

 map:init_music()
 map:set_digging_allowed(true)
  -- Travel
  travel_transporter:set_enabled(false)

end

-- Initialize the music of the map
function map:init_music()
  
  local x_hero, y_hero = hero:get_position()
  if y_hero <  384 then
    if game:get_player_name():lower() == "marin" then
      sol.audio.play_music("maps/out/tal_tal_mountain_range_marin")
    else
      sol.audio.play_music("maps/out/tal_tal_mountain_range")
    end
  else
      sol.audio.play_music("maps/out/overworld")
  end

end

function travel_sensor:on_activated()

    travel_manager:init(map, 3)

end

-- Dors events
function weak_door_1:on_opened()
  sol.audio.play_sound("secret_1")
end
