-- Lua script of custom entity pillar.
-- This script is executed every time a custom entity with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local pillar = ...
local game = pillar:get_game()
local map = pillar:get_map()

pillar:register_event("on_created", function(pillar)

  -- Disable the pillar if the corresponding world savegame exists
  if game:get_value(map:get_world() .. "_" .. pillar:get_name()) then
    pillar:set_enabled(false)
  end
end

local function pillar:start_breaking()

  -- Save the pillar state
  game:set_value(map:get_world() .. "_" .. pillar:get_name(), true)

  -- Freeze the hero
  hero:freeze()

  -- TODO Start shaking the screen and earthquake audio

  -- Wait 1s
  sol.timer.start(1000, function()

    -- TODO Start 3 delayed explosions placed randomly around the pillar base and reset them when ended

    -- TODO Move down pillar sprites, hiding overflow
    falling_movement = sol.movement.create("straight")
    falling_movement:set_speed(1)
    falling_movement:set_angle(3 * math.pi)
    falling_movement:set_max_distance(80)

    falling_movement:start(map:get_entity("pillar_base"):get_sprite())
    falling_movement:start(map:get_entity("pillar"):get_sprite(), function()

      -- TODO Stop explosions and shaking the screen

      -- Unfreeze the hero
      hero:unfreeze()
    end)
  end)
end

-- Function called by the iron_ball custom entity
function pillar:hit_by_iron_ball()
  self:start_breaking()
end