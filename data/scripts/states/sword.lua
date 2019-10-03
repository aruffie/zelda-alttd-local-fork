--[[
  Top-view sword state (custom).

  --EXPERIMANTAL, may be removed at some point.
  
  To use, simply require this file into your jump-enabling item script, then call hero:attack()
--]]

local jm=require("scripts/jump_manager")
local audio_manager=require("scripts/audio_manager")
local state = jm.init("sword")

local hero_meta= sol.main.get_metatable("hero")
local sword_sprite
local tunic_sprite

--this is the function that starts it all
function hero_meta.sword_attack(hero)
  --print "attack on air !"
  if hero:get_state()~="custom" or hero:get_state_object():get_description()~="sword" then
    hero:start_state(state)
  end
end


function state:on_started(old_state_name, old_state_object)
--print "flying attaaaaack"
  jm.setup_collision_rules(state)
  local entity=state:get_entity()
  local game = state:get_game()
  if not game:get_ability("sword") then
    entity:unfreeze()
  end--Should be at least 1 if your jump-enabling item script has checked this before starting this state 

  --Set up sprites
  tunic_sprite = entity:get_sprite("tunic")
  sword_sprite = entity:get_sprite("sword")
  sword_sprite:set_direction(tunic_sprite:get_direction())
  local sword_animation=tunic_sprite:get_animation()
  if sword_animation == "sword_swinging" then
    local old_behavior=sword_sprite.on_animation_finished
    sword_sprite.on_animation_finished=function()
      if entity:get_movement() and entity:get_movement():get_speed()>0 then
        tunic_sprite:set_animation("sword_loading_walking")
        sword_sprite:set_animation("sword_loading_walking")   
      else
        tunic_sprite:set_animation("sword_loading_stopped")
        sword_sprite:set_animation("sword_loading_stopped")
        sword_sprite.on_animation_finished=old_behavior
      end
    end
  else
    tunic_sprite:set_animation("sword", function()
        if game:is_command_pressed("attack") then
          if entity:get_movement() and entity:get_movement():get_speed()>0 then
            tunic_sprite:set_animation("sword_loading_walking")
            sword_sprite:set_animation("sword_loading_walking")   
          else
            tunic_sprite:set_animation("sword_loading_stopped")
            sword_sprite:set_animation("sword_loading_stopped")
          end
        else
          if entity:get_movement() and entity:get_movement():get_speed()>0 then
            tunic_sprite:set_animation("walking") 
          else
            tunic_sprite:set_animation("stopped")
          end          
        end
      end)
  end
end

function state:on_command_released(command)
  local entity=state:get_entity()
  if command =="attack" then
    tunic_sprite = entity:get_sprite("tunic")
    tunic_sprite:set_animation("stopped")
    entity:unfreeze()
    return true
  end
end

function state:on_finished()
  sword_sprite:stop_animation()
  sword_sprite = nil
end