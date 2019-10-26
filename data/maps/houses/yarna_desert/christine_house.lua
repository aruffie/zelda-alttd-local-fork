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

  audio_manager:play_music("41_christine_house")

end

-- Initializes Entities based on player's progress
function map:init_map_entities()
 
  local item = game:get_item("magnifying_lens")
  local variant = item:get_variant()
  if variant >= 9 then
     local hibiscus_sprite = hibiscus:get_sprite()
     hibiscus_sprite:set_animation("full")
  end

end

-- Discussion with Christine
function map:talk_to_christine() 

  local direction4 = christine:get_direction4_to(hero)
  local christine_sprite = christine:get_sprite()
  christine_sprite:set_direction(direction4)
  christine_sprite:set_animation("stopped")
  local item = game:get_item("magnifying_lens")
  local variant = item:get_variant()
  if variant < 8 then
    game:start_dialog("maps.houses.yarna_desert.christine_house.christine_1", function()
        christine_sprite:set_direction(2)
        christine_sprite:set_animation("waiting")
    end)
  elseif variant == 8 then
    game:start_dialog("maps.houses.yarna_desert.christine_house.christine_2", function(answer)
      if answer == 1 then
        game:start_dialog("maps.houses.yarna_desert.christine_house.christine_4", function()
            local hibiscus_sprite = hibiscus:get_sprite()
            hibiscus_sprite:set_animation("full")
            hero:start_treasure("magnifying_lens", 9, nil, function()
              christine_sprite:set_direction(2)
              christine_sprite:set_animation("waiting")
            end)
        end)
      else
        game:start_dialog("maps.houses.yarna_desert.christine_house.christine_3", function()
          christine_sprite:set_direction(2)
          christine_sprite:set_animation("waiting")
        end)
      end
    end)
  else
    game:start_dialog("maps.houses.yarna_desert.christine_house.christine_5", function()
        christine_sprite:set_direction(2)
        christine_sprite:set_animation("waiting")
    end)
  end

end

-- Npcs events
function christine:on_collision_fire()

  return false

end

function christine:on_interaction()

  map:talk_to_christine()

end

function christine_invisible:on_interaction()

  map:talk_to_christine()

end
