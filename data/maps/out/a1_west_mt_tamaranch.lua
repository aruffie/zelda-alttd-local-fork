-- Outside - West Mt Tarmaranch

-- Variables
local map = ...
local game = map:get_game()
local hero = map:get_hero()

local travel_manager = require("scripts/maps/travel_manager")

-- Methods - Functions


-- Events

function map:on_started()

 map:set_music()
 map:set_digging_allowed(true)

  -- Travel
  travel_transporter:set_enabled(false)

end

function map:set_music()

  local x_hero, y_hero = hero:get_position()
  if y_hero < 384 then
    if game:get_player_name():lower() == "marin" then
      sol.audio.play_music("maps/out/mt_tamaranch_marin")
    else
      sol.audio.play_music("maps/out/mt_tamaranch")
    end
  else
      sol.audio.play_music("maps/out/overworld")
  end

end

function travel_sensor:on_activated()

    travel_manager:init(map, 2)

end

--Weak doors play secret sound on opened
function weak_door_1:on_opened() sol.audio.play_sound("secret_1") end
