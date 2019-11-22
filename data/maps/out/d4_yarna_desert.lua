-- Variables
local map = ...
local game = map:get_game()


-- Include scripts
require("scripts/multi_events")
local travel_manager = require("scripts/maps/travel_manager")
local audio_manager = require("scripts/audio_manager")

-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
  -- Entities
  map:init_map_entities()
  -- Digging
  map:set_digging_allowed(true)
  -- Owl slab
  if game:get_value("travel_4") then
    owl_slab:get_sprite():set_animation("activated")
  end

end)

-- Initialize the music of the map
function map:init_music()
  
  audio_manager:play_music("40_animal_village")

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
  
    -- Travel
  travel_transporter:set_enabled(false)
  
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

-- Doors events
function weak_door_1:on_opened()

  audio_manager:play_sound("misc/secret1")

end

-- NPCs events
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

-- Sensors events
function travel_sensor:on_activated()

  travel_manager:init(map, 4)
  owl_slab:get_sprite():set_animation("activated")
  
end

-- Separators events
separator_1:register_event("on_activating", function(separator, direction4)

  if direction4 == 1 then
    audio_manager:play_music("40_animal_village")
  elseif direction4 == 3 then
    audio_manager:play_music("10_overworld")
  end

end)

separator_2:register_event("on_activating", function(separator, direction4)
    
  if direction4 == 0 then
    map.fsa_heat_wave = true
  elseif direction4 == 2 then
    map.fsa_heat_wave = false
  end
  
end)