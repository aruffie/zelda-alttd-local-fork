local main_steps=require("scripts/maps/lib/main_quest_steps_config")

local game_meta=sol.main.get_metatable("game")
function game_meta:get_main_step_index(step_id)
  print ("Requested main quest step for event "..step_id..". Value: "..main_steps[step_id])
  return main_steps[step_id]
end

function game_meta:is_main_step_done(step_id)
  return self:get_value("main_quest_step") >= main_steps[step_id]
end

function game_meta:is_main_step_current(step_id)
  return self:get_value("main_quest_step") == main_steps[step_id]
end

function game_meta:set_main_step_done(step_id)
  return self:set_value("main_quest_step", main_steps[step_id])
end