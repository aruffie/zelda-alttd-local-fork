local carried_meta = sol.main.get_metatable("carried_object")
require ("scripts/multi_events")
local audio_manager=require "scripts/audio_manager"
local m = sol.movement.create("straight")

carried_meta:register_event("on_thrown", function(entity)
    
    audio_manager:play_sound("hero/throw")
    local map = entity:get_map()
    local hero = map:get_hero()
    local shadow = entity:get_sprite("shadow")    
    if shadow then
        print "(throwing time) SHADOW BE GONE !"
        shadow:stop_animation()
      end
    if map:is_sideview() then --Make me follow gravity


      m:set_angle(hero:get_sprite():get_direction()*math.pi/2)
      m:set_speed(92)
      m:start(entity)
    end

  end)

carried_meta:register_event("on_created", function(entity)

    local map=entity:get_map()
    local shadow = entity:get_sprite("shadow")
    if shadow then
        print "(creation time) SHADOW BE GONE !"
        shadow:stop_animation()
      end
    if map:is_sideview() then
      for name, s in entity:get_sprites() do
        s:set_xy(0,2)
      end



    end

  end)