-- Configuration of the phone manager.
-- Feel free to change these values.

return {
  message_2 = {
    message_key = 2,
    activation_condition = function(map)
      return
        map:get_game():get_value("first_phone_call")
    end
  },
  message_3 = {
    message_key = 3,
    activation_condition = function(map)
      return map:get_game():get_value("main_quest_step") > 7
    end
  }
  message_4 = {
    message_key = 3,
    activation_condition = function(map)
      return map:get_game():get_value("main_quest_step") > 9
    end
  }
}