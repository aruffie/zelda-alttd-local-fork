local map_meta = sol.main.get_metatable("map")


function map_meta:owl_appear(step, callback)

  local game = self:get_game()
  local hero = self:get_entity("hero")
  local owl = self:get_entity("owl_"..step)
  
  game:set_pause_allowed(false)
  owl:set_visible(true)
  owl:get_sprite():set_animation("walking")
  local m = sol.movement.create("target")
  local x,y = hero:get_position()
  y = y - 32
  m:set_target(x, y)
  m:set_speed(60)
  m:set_ignore_obstacles(true)
  m:start(owl)
  sol.audio.play_music("scripts/meta/map/the_wise_owl")
  game:set_value("owl_"..step, true)
  hero:set_direction(1)
  hero:freeze()
  m:start(owl, function() 
    owl:get_sprite():set_animation("talking")
    game:start_dialog("scripts.meta.map.owl_"..step, function()
      owl:get_sprite():set_animation("walking")
      local m2 = sol.movement.create("target")
      local position = self:get_entity("owl_"..step.."_position")
      m2:set_target(position)
      m2:set_speed(100)
      m2:set_ignore_obstacles(true)
      m2:start(owl, function()
        owl:set_visible(false)
        if callback ~= nil then
          callback()
        else
          hero:unfreeze()
          --game:set_pause_allowed(true)
          --self:set_music()
        end
      end)
    end)      
  end)

end
