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
    repeated_behavior_delay = 2000,
    repeated_behavior = function(companion)
      print(companion:get_state())
      if companion:get_state() == "eat_enemy" then
        companion:set_state("stopped")
        return false
      end
      local distance = 64
      local map = companion:get_map()
      local hero = map:get_hero()
      local x,y, layer = companion:get_position()
      local width = distance * 2
      local height = distance * 2
      local enemies = {}
      for entity in map:get_entities_in_rectangle(x - 16, y - 16 , width, height) do
        if entity:get_type() == "enemy" then
          enemies[#enemies + 1] = entity
        end
      end
      local index = math.random(1, #enemies)
      if enemies[index] ~= nil then
        --companion:stop_movement()
        companion:set_state("eat_enemy")
        print("eat")
        -- Bowwow eat enemy
        local enemy = enemies[index]
        local direction4 = companion:get_direction4_to(enemy)
        companion:get_sprite():set_direction(direction4)
        local movement_1 = sol.movement.create("target")
        movement_1:set_target(enemy)
        movement_1:set_speed(100)
        movement_1:set_ignore_obstacles(true)
        movement_1:start(companion)
        function movement_1:on_finished()
          enemy:set_life(0)
          companion:set_state("stopped")
        end
      end
    end
  },
  ghost = {
    sprite = "npc/ghost"
  },
  flying_rooster = {
    sprite = "npc/flying_rooster"
  }
}