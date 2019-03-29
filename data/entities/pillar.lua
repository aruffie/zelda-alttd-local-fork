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

local cinematic_manager = require("scripts/maps/cinematic_manager")
local map_tools = require("scripts/maps/map_tools")

pillar:register_event("on_created", function(pillar)

  pillar:set_traversable_by(false)
  
  -- Display the top sprite if the corresponding world savegame doesn't exist, else disable the pillar.
  if not game:get_value(map:get_world() .. "_" .. pillar:get_name()) then
    local pillar_top_sprite = pillar:create_sprite("entities/statues/pillar_top", "top")
    pillar_top_sprite:set_xy(0, -32)
  else
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

  -- Set cinematic mode
  -- TODO map:set_cinematic_mode(true, {entities_ignore_suspend = {hero, pillar}})

  -- Start earthquake
  map_tools.start_earthquake({count = 64, amplitude = 4, speed = 90})

  -- Start 3 chained explosions
  for i = 1, 3 do
    sol.timer.start((i - 1) * 500, function()
      map_tools.start_chained_explosion_on_entity(pillar, 32, function()
        -- If this is the last explosion, restore initial states
        if map:get_entities_count("chained_explosion") == 1 then
          -- TODO map:set_cinematic_mode(false)
        end
      end)
    end)
  end

  sol.timer.start(500, function()

    -- Start collapse animation on the pillar and its top entity
    pillar:get_sprite():set_animation("collapse")
    pillar:get_sprite("top"):set_animation("collapse")
  end)
end

-- Function called by the iron ball
function pillar:on_hit_by_carriable(carriable)
  
  if carriable:get_name() == "iron_ball" then
    pillar:start_breaking()
  end
end