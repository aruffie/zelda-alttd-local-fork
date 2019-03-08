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

local audio_manager = require("scripts/audio_manager")

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

-- Start an explosion placed randomly around the entity coordinates and restart it while the entity is enabled
function map:start_chained_explosion_on_entity(entity, max_distance, callback)

  local x, y, layer = entity:get_position()
  math.randomseed(sol.main.get_elapsed_time())
  
  -- TODO audio_manager:play_sound("explosion")

  local explosion = map:create_explosion(
      {name = "chained_explosion", x = x + math.random(-max_distance, max_distance), y = y + math.random(-max_distance, max_distance), layer = layer})
  if explosion ~= nil then -- Avoid Errors when closing the game while a chained explosion is running
    explosion:register_event("on_removed", function(explosion)
      if entity:is_enabled() then
        map:start_chained_explosion_on_entity(entity, max_distance, callback)
      else
        callback()
      end
    end)
  end
end

-- Shake the screen
function map:start_earthquake(shake_config)

  map:start_coroutine(function()
    local camera = map:get_camera()
    local timer_sound = sol.timer.start(hero, 0, function()
      -- TODO audio_manager:play_sound("misc/dungeon_shake")
      return 450
    end)
    timer_sound:set_suspended_with_map(false)
    wait_for(camera.shake, camera, shake_config)
    timer_sound:stop()
  end)
end

function pillar:start_breaking()

  -- Save the pillar state
  game:set_value(map:get_world() .. "_" .. pillar:get_name(), true)

  -- Freeze the hero
  hero:freeze()

  -- Start earthquake
  map:start_earthquake({count = 64, amplitude = 4, speed = 90})

  -- Start 3 chained explosions
  for i = 1, 3 do
    sol.timer.start((i - 1) * 500, function()
      map:start_chained_explosion_on_entity(pillar, 32, function()
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

-- Function called by the iron ball ("portable" custom entity)
function pillar:hit_by_portable_entity(portable)
  
  if portable:get_name() == "iron_ball" then
    pillar:start_breaking()
  end
end