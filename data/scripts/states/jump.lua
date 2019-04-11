--Newer version of the custom jump, allows for the sword to be used mid-air.

local state = sol.state.create("jump")
state:set_can_use_item(false)
state:set_can_control_movement(true)
state:set_can_control_direction(false)
state:set_affected_by_ground("hole", false)
state:set_affected_by_ground("lava", false)
state:set_affected_by_ground("deep_water", false)

require("scripts/states/flying_sword")
local jm=require("scripts/jump_manager")


function state:on_started()
  
  --print "ok ok"
  local map = state:get_map()
  local hero = state:get_entity()
  local x,y,layer = hero:get_position() 
  local bx, by, bh, bw=hero:get_bounding_box()

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
  jm.start(hero)
  --Safety check: if we are not already in this state then start it
  if hero:get_state() ~= "custom" or hero:get_state_object():get_description()~="jump" then
    hero:start_state(state)
  end
end