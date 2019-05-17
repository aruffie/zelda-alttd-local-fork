--Newer version of the custom jump, allows for the sword to be used mid-air.
require("scripts/states/jumping_sword")
local jump_manager=require("scripts/jump_manager")
local state = jump_manager.init("jumping")




function state:on_started(previous_state_name, previous_state_object)
  
  --print "ok ok"
  local map = state:get_map()
  local hero = state:get_entity()
  local x,y,layer = hero:get_position() 
  local bx, by, bh, bw=hero:get_bounding_box()
  hero:get_sprite():set_animation("jumping")

end

function state:on_command_pressed(command)
  local e=state:get_entity()
  if command =="attack" and state:get_game():get_ability("sword")>0 then
    e:start_flying_attack()
    return true
  end
end

local hero_meta=sol.main.get_metatable("hero")

function hero_meta.start_jumping(hero)
  --TODO use custom state for actual jumping

  --Safety check: if we are not already in this state then start it
  if hero:get_state() ~= "custom" or hero:get_state_object():get_description()~="jumping" then
    hero:start_state(state)
  end
  jump_manager.start(hero)
end