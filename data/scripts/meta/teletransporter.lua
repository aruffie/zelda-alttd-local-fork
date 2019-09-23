local teletransporter_meta=sol.main.get_metatable("teletransporter")

teletransporter_meta:register_event("on_activated", function(teletransporter)
    local game=teletransporter:get_game()
    local hero=game:get_hero()
    local ground=hero:get_ground_below()
    print ("last known ground before teletransportation: "..ground)
    game:set_value("tp_ground", ground)

  end)