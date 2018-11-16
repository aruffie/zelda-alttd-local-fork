-- Variables
local map = ...
local game = map:get_game()

local travel_manager = require("scripts/maps/travel_manager")

-- Map events
function map:on_started()

  map:set_digging_allowed(true)
  -- Travel
  travel_transporter:set_enabled(false)

end

-- Initialize the music of the map
function map:init_music()
  
  audio_manager:play_music("animal_village")

end

-- Discussion with Rabbit 1
function map:talk_to_rabbit_1()

  game:start_dialog("maps.out.yarna_desert.rabbit_1_1")

end

-- Discussion with Rabbit 2
function map:talk_to_rabbit_2()

      game:start_dialog("maps.out.yarna_desert.rabbit_2_1")

end

-- Discussion with Rabbit 3
function map:talk_to_rabbit_3()

      game:start_dialog("maps.out.yarna_desert.rabbit_3_1")

end

-- Discussion with Walrus
function map:talk_to_walrus()

      game:start_dialog("maps.out.yarna_desert.walrus_1")

end

-- Sensor events
function travel_sensor:on_activated()

    travel_manager:init(map, 4)

end

-- Separator events
separator_1:register_event("on_activating", function(separator, direction4)

  if direction4 == 1 then
    audio_manager:play_music("animal_village")
  elseif direction4 == 3 then
    audio_manager:play_music("10_overworld")
  end


end)

-- NPC events
function rabbit_1:on_interaction()

  map:talk_to_rabbit_1()

end

function rabbit_2:on_interaction()

  map:talk_to_rabbit_2()

end

function rabbit_3:on_interaction()

  map:talk_to_rabbit_3()

end

function walrus_invisible:on_interaction()

  map:talk_to_walrus()

end

-- Dors events
function weak_door_1:on_opened()

  sol.audio.play_sound("secret_1")

end