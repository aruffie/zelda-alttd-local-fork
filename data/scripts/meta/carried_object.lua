local carried_meta = sol.main.get_metatable("carried_object")
require ("scripts/multi_events")
local audio_manager=require "scripts/audio_manager"
local entity_manager = require("scripts/maps/entity_manager")

local m = sol.movement.create("straight")

carried_meta:register_event("on_thrown", function(entity)

    audio_manager:play_sound("hero/throw")
    local map = entity:get_map()
    local hero = map:get_hero()
    local shadow = entity:get_sprite("shadow")    
    if shadow then
      entity:remove_sprite(shadow)
      error("the shadow should already have been removed at this point")
    end
    if map:is_sideview() then --Make me follow gravity


      m:set_angle(hero:get_sprite():get_direction()*math.pi/2)
      m:set_speed(92)
      m:start(entity)
    end

  end)

carried_meta:register_event("on_lifted", function(entity)
    local shadow = entity:get_sprite("shadow")    
    if shadow then
      error("the shadow should already have been removed at this point")
    end
  end)
carried_meta:register_event("on_removed", function(entity)
    if entity:get_ground_below() =="hole" then
      entity_manager:create_falling_entity(entity)
    end
  end)

carried_meta:register_event("on_created", function(entity)

    local map=entity:get_map()
    local shadow = entity:get_sprite("shadow")
    if shadow then
      debug_print "(carried object creation time) SHADOW BE GONE !"
      entity:remove_sprite(shadow)
    end
    if map:is_sideview() then
      for name, s in entity:get_sprites() do
        s:set_xy(0,2)
      end
    end

  end)