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

  -- Reset all states and animations when collapse animation is finished
  pillar:get_sprite():register_event("on_animation_finished", function(pillar, animation)
    if animation == "collapse" then

      -- TODO Stop explosions and shaking the screen

      -- Unfreeze the hero
      hero:unfreeze()
    end
  end)
end)

function pillar:start_breaking()

  -- Save the pillar state
  game:set_value(map:get_world() .. "_" .. pillar:get_name(), true)

  -- Freeze the hero
  hero:freeze()

  -- TODO Start shaking the screen and earthquake audio

  -- Wait 1s
  sol.timer.start(1000, function()

    -- TODO Start 3 delayed explosions placed randomly around the pillar base and reset them when ended

    -- Start collapse animation on the pillar and its top entity
    local pillar_top_sprite = map:get_entity(pillar:get_name():gsub("pillar_", "pillar_top_", 1)):get_sprite()
    pillar:get_sprite():start_animation("collapse")
    pillar_top_sprite:start_animation("collapse")
  end)
end

-- Function called by the iron_ball custom entity
function pillar:hit_by_iron_ball()
  start_breaking()
end