local map=...

function key_test_switch:on_activated()
  local x,y,layer=key_spawn_point:get_position()
  local key=map:create_pickable({
      x=x,
      y=y,
      layer=layer,
      treasure_name="small_key",
    })
  key:fall_from_ceiling(120, "hero/jump", function()
      print("key dropped")
    end)
  sol.timer.start(self, 1000, function()
      self:set_activated(false)
    end)
end

function key_test_switch_2:on_activated()
  map:start_coroutine(function()
      local options={
        --entities_ignore_suspend={test_key},
      }
      map:set_cinematic_mode(true, options)
      test_key:set_enabled(true)
      test_key:fall_from_ceiling(192, "hero/cliff_jump", function()
          test_key:set_enabled(false)
          key_test_switch_2:set_activated(false)
        end)
      wait(2000)
      map:set_cinematic_mode(false, options)
    end)
end
