--[[

  Newer version of the top-view custom jump, allows for the sword to be used mid-air.

  To use, simply require this file into your jump-enabling item script, then call hero:start_jumping()
  Note, this script only handles (for now?) jumping with no item being simultaneously being used (unless the item scripts handles this case on it's own). If you want to be able to use the sword while jumping, then require "states/jumping_sword" too.

  This script is mostly a wrapper, all this does is setup the custom state and pass it to the jump manager system, who will actually do the animation.
  
--]]

require("scripts/states/jumping_sword")
local jump_manager=require("scripts/jump_manager")
local state = jump_manager.init("jumping")


function state:on_started(previous_state_name, previous_state_object)
  
  local map = state:get_map()
  local hero = state:get_entity()
  local x,y,layer = hero:get_position() 
  local bx, by, bh, bw=hero:get_bounding_box()
  hero:get_sprite():set_animation("jumping")

end

--Use the swoed mid-air
--SUGGESTION : use a single state for all jumping combinations since they use the same core movement ?
function state:on_command_pressed(command)
  local e=state:get_entity()
  if command =="attack" and state:get_game():get_ability("sword")>0 then
    e:start_flying_attack()
    return true
  end
end

local hero_meta=sol.main.get_metatable("hero")

--This is the function that starts the whole jumping process
function hero_meta.jump(hero)

  --Safety check: if we are not already in this state then start it
  if hero:get_state() ~= "custom" or hero:get_state_object():get_description()~="jumping" then
    hero:start_state(state)
  end
  -- Now, start the actual jump effect, regardless of whether we were alrealy jumping (the jumping manager will check the status on it's own).
  jump_manager.start(hero)
end