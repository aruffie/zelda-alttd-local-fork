-- Lua script of item zol_green.
-- This script is executed only once for the whole game.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local item = ...
local game = item:get_game()

function item:on_created()

  item:set_sound_when_brandished("wrong")
end

function item:on_obtaining()

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
