-- Outside - West Mt Tamaranch

-- Variables
local map = ...
local game = map:get_game()
local hero = map:get_hero()
local owl_manager = require("scripts/maps/owl_manager")


-- Methods - Functions

-- Initialize the music of the map
function map:init_music()
  
  local x_hero, y_hero = hero:get_center_position()
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

-- Set if the egg is opened or not.
function map:set_egg_opened(is_opened)
  if is_opened then
    egg_door:get_sprite():set_animation("opened")
    egg_door_top:get_sprite():set_animation("opened")
    egg:set_traversable_by(true)
  else
    egg_door:get_sprite():set_animation("closed")
    egg_door_top:get_sprite():set_animation("closed")
    egg:set_traversable_by(false)
  end
end

-- Events

function map:on_started(destination)

  map:init_music()
  -- Owl
  owl_6:set_enabled(false)
  -- Remove the big stone if you come from the secret cave
  if destination == stair_arrows_upgrade then
    secret_stone:set_enabled(false)
  end
  -- Signs
  photographer_sign:get_sprite():set_animation("photographer_sign")

  -- Egg
  self:set_egg_opened(false)
end

function owl_6_sensor:on_activated()

  if game:get_value("owl_6") ~= true then
    owl_manager:appear(map, 6, function()
      map:init_music()
    end)
  end

end
