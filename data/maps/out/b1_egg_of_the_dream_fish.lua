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
      sol.audio.play_music("maps/out/tal_tal_mountain_range_marin")
    else
      sol.audio.play_music("maps/out/tal_tal_mountain_range")
    end
  else
      sol.audio.play_music("maps/out/overworld")
  end
end


-- Events

function map:on_started(destination)

  -- Owl
  owl_6:set_enabled(false)
  -- Remove the big stone if you come from the secret cave
  if destination == stair_arrows_upgrade then
    secret_stone:set_enabled(false)
  end
  -- Signs
  photographer_sign:get_sprite():set_animation("photographer_sign")

end

function owl_6_sensor:on_activated()

  if game:get_value("owl_6") ~= true then
    owl_manager:appear(map, 6, function()
      map:init_music()
    end)
  end

end
