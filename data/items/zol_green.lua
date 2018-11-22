-- Lua script of item "zol green".
-- This script is executed only once for the whole game.

-- Variables
local item = ...
local game = item:get_game()

-- Event called when the game is initialized.
function item:on_created()

  item:set_sound_when_brandished(nil)
  
end

function item:on_obtaining()

  -- Sound
  audio_manager:play_sound("others/error")
  -- Create enemy
  local map = game:get_map()
  local x, y, layer = map:get_hero():get_position()
  map:create_enemy({
    x = x,
    y = y,
    layer = layer,
    breed = "zol_green",
    direction = 3,
  })

-- Skip the brandish animation
-- when obtaining a Zol in a chest.
  map:get_hero():set_animation("stopped")
    
end
