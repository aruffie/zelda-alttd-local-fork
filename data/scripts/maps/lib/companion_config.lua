-- Configuration of the companion manager.
-- Feel free to change these values.

return {
  marin = {
    sprite = "npc/marin",
    activation_condition = function(map)
      if map:get_game():is_in_dungeon() then
        return false
      end
      local step = map:get_game():get_value("main_quest_step")
      return step == 23
    end
  },
  bowwow = {
    sprite = "npc/bowwow",
    activation_condition = function(map)
      local excluded_maps = {
        ["houses/meow_house"] = true
      }
      if excluded_maps[map:get_id()] then
        return false
      end
      if map:get_game():is_in_dungeon() then
        return false
      end
      local step = map:get_game():get_value("main_quest_step")
      return step >= 10 and step < 12
    end,
  },
  ghost = {
    sprite = "npc/ghost"
  },
  flying_rooster = {
    sprite = "npc/flying_rooster"
  }
}