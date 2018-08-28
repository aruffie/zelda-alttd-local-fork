-- Configuration of the companion manager.
-- Feel free to change these values.

return {
  marin = {
    sprite = "npc/marin",
    activation_condition = function(map)
      if map.is_companion_allowed ~= nil and not map:is_companion_allowed() then
        return false
      end
      local step = map:get_game():get_step()
      return step == 23
    end
  },
  bowwow = {
    sprite = "npc/bowwow",
    activation_condition = function(map)
      if map.is_companion_allowed ~= nil and not map:is_companion_allowed() then
        return false
      end
      local step = map:get_game():get_step()
      return step >= 10 and step < 12
    end,
  }
}