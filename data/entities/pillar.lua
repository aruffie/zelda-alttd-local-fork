----------------------------------
--
-- Pillar entity that can collapse.
-- 
-- Methods : pillar:start_breaking()
-- Events :  pillar:on_collapse_finished()
--
----------------------------------

local pillar = ...
local game = pillar:get_game()
local map = pillar:get_map()
local hero = map:get_hero()

local cinematic_manager = require("scripts/maps/cinematic_manager")
local map_tools = require("scripts/maps/map_tools")

-- Initialize the pillar.
pillar:register_event("on_created", function(pillar)

  pillar:set_traversable_by(false)
  
  -- Display the top sprite if the corresponding world savegame doesn't exist, else disable the pillar.
  if not game:get_value(map:get_world() .. "_" .. pillar:get_name()) then
    local pillar_top_sprite = pillar:create_sprite("entities/statues/pillar", "top")
    pillar_top_sprite:set_animation("stopped_top")
    pillar_top_sprite:set_xy(0, -32)
  else
    pillar:set_enabled(false)
  end

  -- Call events and disable entity when collapse ended.
  pillar:get_sprite():register_event("on_animation_finished", function(pillar_sprite, animation)
    if animation == "collapse" then
      pillar:set_enabled(false)
    end
  end)
end)

-- Make hero and all region enemies invincible or vulnerable.
local function make_all_invincible(invincible)
  hero:set_invincible(invincible)
  for entity in map:get_entities_in_region(hero) do
    if entity:get_type() == "enemy" then
      if invincible then
        entity:set_invincible()
      else
        entity:set_default_attack_consequences()
      end
    end
  end
end

-- Make the pillar explode, collapse and then disabled.
function pillar:start_breaking()

  local save_name = map:get_world() .. "_" .. pillar:get_name()
  if game:get_value(save_name) then
    return -- Pillar is already breaking.
  end

  -- Save the pillar state.
  game:set_value(save_name, true)

  -- Start cinematic.
  map:set_cinematic_mode(true, {entities_ignore_suspend = {pillar}})
  make_all_invincible(true)

  -- Start earthquake.
  map_tools.start_earthquake({count = 64, amplitude = 4, speed = 90})

  -- Start 3 chained explosions.
  for i = 1, 3 do
    explosion_timer = sol.timer.start((i - 1) * 500, function()
      map_tools.start_chained_explosion_on_entity(pillar, 32, function()
        -- If this is the last explosion, restore initial states and call the collapse finished event.
        if not pillar:is_enabled() and map:get_entities_count("chained_explosion") == 1 then
          make_all_invincible(false)
          map:set_cinematic_mode(false, {entities_ignore_suspend = {pillar}}) 
          if pillar.on_collapse_finished then
            pillar:on_collapse_finished() -- Call event
          end
        end
      end)
    end)
    explosion_timer:set_suspended_with_map(false)
  end

  -- Start collapse animation on the pillar and its top entity.
  collapse_timer = sol.timer.start(500, function() 
    pillar:get_sprite():set_animation("collapse")
    pillar:get_sprite("top"):set_animation("collapse_top")
  end)
  collapse_timer:set_suspended_with_map(false)
end