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
  test_key:set_enabled(true)
  test_key:fall_from_ceiling(192, nil, function()

    end)
    sol.timer.start(self, 1000, function()
      self:set_activated(false)
    end)
end
