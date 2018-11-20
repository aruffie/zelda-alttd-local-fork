-- Lua script of custom entity drop_bridge.
-- This script is executed every time a custom entity with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:is_hookable()
  return false
end


-- Event called when the custom entity is initialized.
function entity:on_created()

  local sprite = entity:get_sprite()
  local hero = map:get_hero()
  local direction_hero = hero:get_direction()
  local direction_hero_opposite = direction_hero + 2
  if direction_hero_opposite >= 4 then
    direction_hero_opposite = direction_hero_opposite - 4
  end

end

function entity:open_bridge()

end

