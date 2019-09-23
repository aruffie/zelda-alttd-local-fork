local object = {}

local audio_manager=require "scripts/audio_manager"
require "scripts/multi_events"
-- Falling from ceiling
-- Works with any type of entity
-- Version 0.1 - MetalZelda

--[[
  Make it work:
 
  - Save this script anywhere you want
  - In any script (metatable script is better):
 
  Example: I want to make this available for the hero
  local fall_manager = require("path_to_the_script")
  fall_manager:create("hero")

  Recommended way to make this work:
  -> in main.lua

  local fall_manager = require("path_to_the_script")
  local entities_fall_compatibility = { "hero", "enemy", "npc"}
  for _, entities in ipairs(entities_fall_compatibility) do
    fall_manager:create(entities)
  end
 
 
  Careful, it only work with map entities
 
  To active it, simply call
    - hero:fall_from_ceiling(height, sound, callback) where
	 
	  height = the height of the falling things (must be positive)
	  sound = any sound you wanna play when the falling animation starts
	  callback = what to do when it finished (text, cutscene, death, etc)
	 
	- Remember that you can implement it anywhere else, the target only need to be an entity / sprite
]]

function object:create(meta)
  local object_meta = sol.main.get_metatable(meta)
  local currently_falling = false

  function object_meta.fall_from_ceiling(entity, height, sound, callback)
    currently_falling = true

    if entity:get_type() == "hero" then
      -- This means that self returns the hero entity, avoid him from moving.
      entity:freeze()
    end

    -- Get the current object position
    local cx, cy, clayer = entity:get_position()
    local map = entity:get_map()

    -- Draw a shadow in the entity's real position
    local shadow = map:create_custom_entity({
        x = cx,
        y = cy,
        layer = clayer,
        width = 16,
        height = 16,
        sprite = "entities/shadow",
        direction = 0
      })


    local first_active_sprite = nil

    -- Depending on things, obejct might have different sprite that is synchronized to him
    for sprite_name, sprite in entity:get_sprites() do
      sprite:set_xy(0, -height)

      if first_active_sprite ~= nil then
        first_active_sprite = sprite_name
      end
    end

    local target_sprite = entity:get_sprite(first_active_sprite)

    if sound ~= nil then
      audio_manager:play_sound(sound)
    end
    if entity:get_type()=="hero" then
      entity.ceiling_drop_spin_timer=sol.timer.start(entity, 100, function()
          target_sprite:set_direction((target_sprite:get_direction()+1)%target_sprite:get_num_directions())

          return true
        end)
    end
    local movement = sol.movement.create("straight")
    movement:set_max_distance(height)
    movement:set_angle(3 * math.pi / 2)
    movement:set_speed(300)
    movement:set_ignore_obstacles(true)
    movement:start(target_sprite, function()
        -- Movement finished, disable the falling movement
        first_active_sprite = nil
        currently_falling = false



        if meta == "hero" then
          entity.ceiling_drop_spin_timer:stop()
          entity.ceiling_drop_spin_timer=nil
          entity:unfreeze()
        end

        if callback ~= nil then
          callback()
        end

        shadow:remove()
      end)


    -- Notify the game to synchronize all sprites during the freefall movement if any
    function movement:on_position_changed()
      local x, y = target_sprite:get_xy()

      local animation = shadow:get_sprite():get_animation()
      local current_height = -y

      -- Adding some shadow stuff here

      if current_height == height / 1.5 then
        if animation ~= "small" then
          shadow:get_sprite():set_animation("small")
        end
      elseif current_height == height / 4 then
        if animation ~= "big" then
          shadow:get_sprite():set_animation("big")
        end
      end

      -- Depending on things, obejct might have different sprite that is synchronized to him
      for _, sprite in entity:get_sprites() do
        sprite:set_xy(x, y)
      end

    end	
  end
end


return object