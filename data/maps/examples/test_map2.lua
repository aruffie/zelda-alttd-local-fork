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