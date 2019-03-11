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
local hero = map:get_hero()

local map_tools = require("scripts/maps/map_tools")

pillar:register_event("on_created", function(pillar)

  pillar:set_traversable_by(false)

  -- Disable the pillar if the corresponding world savegame exists
  if game:get_value(map:get_world() .. "_" .. pillar:get_name()) then
    pillar:set_enabled(false)
  end

  -- Reset all states and animations when collapse animation is finished
  pillar:get_sprite():register_event("on_animation_finished", function(pillar_sprite, animation)

    if animation == "collapse" then
      pillar:set_enabled(false)
    end
  end)
end)

function pillar:start_breaking()

  -- Save the pillar state
  game:set_value(map:get_world() .. "_" .. pillar:get_name(), true)

  -- Freeze the hero
  hero:freeze()

  -- Start earthquake
  map_tools.start_earthquake({count = 64, amplitude = 4, speed = 90})

  -- Start 3 chained explosions
  for i = 1, 3 do
    sol.timer.start((i - 1) * 500, function()
      map_tools.start_chained_explosion_on_entity(pillar, 32, function()
        -- If this is the last explosion, unfreeze the hero
        if map:get_entities_count("chained_explosion") == 1 then
          hero:unfreeze()
        end
      end)
    end)
  end

  sol.timer.start(500, function()

    -- Start collapse animation on the pillar and its top entity
    local pillar_top_sprite = map:get_entity(pillar:get_name():gsub("pillar_", "pillar_top_", 1)):get_sprite()
    pillar:get_sprite():set_animation("collapse")
    pillar_top_sprite:set_animation("collapse")
  end)
end

-- Function called by the iron ball
function pillar:hit_by_carriable(carriable)
  
  if carriable:get_name() == "iron_ball" then
    pillar:start_breaking()
  end
end