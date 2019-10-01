local phone_manager = {}

function phone_manager:talk(map)

  local game = map:get_game()
  local hero = map:get_hero()
  local phone = map:get_entity("phone")
  local phone_sprite = phone:get_sprite()
  local messages = require("scripts/maps/lib/phone_messages_config")
  local message_key = 1
  -- We go through the list of companions
  for key, params in pairs(messages) do
    if params.activation_condition ~= nil and params.activation_condition(map) then
      message_key = key
    end
  end
  phone_sprite:set_animation("calling")
  hero:freeze()
  hero:get_sprite():set_ignore_suspend(true)
  hero:set_animation("pickup_phone", function()
    hero:set_animation("calling")
    game:start_dialog("maps.houses.phone_booth." .. message_key, function() 
      hero:set_animation("hangup_phone", function()
        hero:unfreeze()
        phone_sprite:set_animation("stopped")
        hero:get_sprite():set_ignore_suspend(false)
      end)  
    end)
  end)

end

return phone_manager