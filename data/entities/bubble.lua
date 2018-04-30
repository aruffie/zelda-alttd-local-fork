-- Lua script of custom entity bubble.
-- This script is executed every time a custom entity with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()

  local sprite = entity:get_sprite()
  function sprite:on_animation_finished(animation)
    if animation == "walking" then
      sprite:set_animation("stopped")
      local delay = math.random(5000)
      sol.timer.start(entity, delay, function()
        sprite:set_animation("walking")
      end)
    end
  end
  local delay = math.random(5000)
  sol.timer.start(entity, delay, function()
    sprite:set_animation("walking")
  end)

end
