-- Configuration of the phone manager.
-- Feel free to change these values.

return {
  O = {
    activation_condition = function(map)
      local step = map:get_game():get_value("main_quest_step")
      return step == 23
    end
  }
}