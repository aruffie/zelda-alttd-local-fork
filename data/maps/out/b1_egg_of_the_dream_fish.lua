-- Variables
local map = ...
local game = map:get_game()
local hero = map:get_hero()

-- Include scripts
local travel_manager = require("scripts/maps/travel_manager")
local owl_manager = require("scripts/maps/owl_manager")
local audio_manager = require("scripts/audio_manager")


-- Map events
function map:on_started(destination)

  -- Music
  map:init_music()
  -- Entities
  map:init_map_entities()
  -- Digging
  map:set_digging_allowed(true)
  -- Owl
  owl_6:set_enabled(false)
  
end

-- Initialize the music of the map
function map:init_music()
  
  local x_hero, y_hero = hero:get_center_position()
  if y_hero < 384 then
    audio_manager:play_music("46_tal_tal_mountain_range")
  else
    audio_manager:play_music("10_overworld")
  end
end

-- Initializes Entities based on player's progress
function map:init_map_entities()
  
  -- Remove the big stone if you come from the secret cave
  if destination == stair_arrows_upgrade then
    secret_stone:set_enabled(false)
  end
  -- Egg
  self:set_egg_opened(false)

end

-- Set if the egg is opened or not.
function map:set_egg_opened(is_opened)
  
  if is_opened then
    egg_door:get_sprite():set_animation("opened")
    egg_door_top:get_sprite():set_animation("opened")
  else
    egg_door:get_sprite():set_animation("closed")
    egg_door_top:get_sprite():set_animation("closed")
  end
  
end

-- Sensors events
function owl_6_sensor:on_activated()

  if game:get_value("owl_6") ~= true then
    owl_manager:appear(map, 6, function()
      map:init_music()
    end)
  end

end
