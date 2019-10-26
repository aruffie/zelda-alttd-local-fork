-- Variables
local map = ...
local game = map:get_game()

-- Include scripts
require("scripts/multi_events")
local audio_manager = require("scripts/audio_manager")


-- Map events
map:register_event("on_started", function(map, destination)

  -- Music
  map:init_music()
    -- Entities
  map:init_map_entities()

end)

-- Initialize the music of the map
function map:init_music()

  audio_manager:play_music("12_house")

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
 
  sol.timer.start(hippo, 2000, function()
    hippo:get_sprite():set_animation("embarrassed")
  end)

end

-- Discussion with hippo
function map:talk_to_hippo()

  local direction = hero:get_direction()
  hippo:get_sprite():set_direction(direction)
  game:start_dialog("maps.houses.yarna_desert.painter_house.hippo_1")

end

-- Discussion with painter
function map:talk_to_painter()

  local direction4 = painter:get_direction4_to(hero)
  painter:get_sprite():set_animation("waiting")
  painter:get_sprite():set_direction(direction4)
  game:start_dialog("maps.houses.yarna_desert.painter_house.painter_1", function()
    painter:get_sprite():set_animation("painting")
  end)

end

-- NPCs events
function hippo:on_interaction()

  map:talk_to_hippo()

end

function painter:on_interaction()

  map:talk_to_painter()

end

function painter_invisible_1:on_interaction()

  map:talk_to_painter()

end

function painter_invisible_2:on_interaction()

  map:talk_to_painter()

end

function painter_invisible_3:on_interaction()

  map:talk_to_painter()

end

function painter_invisible_4:on_interaction()

  map:talk_to_painter()

end

-- Wardrobes
for wardrobe in map:get_entities("wardrobe") do
  function wardrobe:on_interaction()
    game:start_dialog("maps.houses.wardrobe_1", game:get_player_name())
  end
end
