

--[[
  Top-view custom jump with sword being loaded.

  To use, simply require this file into your jump-enabling item script, then call hero:start_jumping()
  Note, this script only handles (for now?) jumping with the sword being simultaneously being used (unless the item scripts handles this case on it's own).
  Don't forget to require "states/jumping" along this file so you can jump with bare hands too.

  This script is mostly a wrapper, all this does is setup the custom state and pass it to the jump manager system, who will actually do the animation.
--]]

local jump_manager
local audio_manager=require("scripts/audio_manager")

local state = sol.state.create("jumping_sword_loading")
state:set_can_use_item(false)
state:set_can_use_item("sword", true)
state:set_can_use_item("shield", true)
state:set_can_use_item("feather", true)
state:set_can_use_item("fire_rod", true)
state:set_can_cut(false) --TODO refine me
state:set_can_control_movement(true)
state:set_can_control_direction(false)
state:set_can_traverse("stairs", false)



local hero_meta= sol.main.get_metatable("hero")
local sword_sprite
local tunic_sprite
local stars_sprite

--this is the function that starts it all
function hero_meta.jump_sword_loading(hero)
  --print "attack on air !"
  if hero:get_state()~="custom" or hero:get_state_object():get_description()~="jumping_sword_loading" then
    hero:start_state(state)
  end
end


function state:on_started(old_state_name, old_state_object)
--print "flying attaaaaack"
  local entity=state:get_entity()
  local game = state:get_game()
  --Set up sprites
  tunic_sprite = entity:get_sprite("tunic")
  sword_sprite = entity:get_sprite("sword")
  stars_sprite = entity:get_sprite("sword_stars")
  stars_sprite:set_direction(tunic_sprite:get_direction())
  if entity:get_movement() and entity:get_movement():get_speed()>0 then
    tunic_sprite:set_animation("sword_loading_walking")
    sword_sprite:set_animation("sword_loading_walking")   
  else
    tunic_sprite:set_animation("sword_loading_stopped")
    sword_sprite:set_animation("sword_loading_stopped")
  end
  stars_sprite:set_animation("loading")

  sol.timer.start(state, 1000, function()
      entity.sword_loaded=true
      audio_manager:play_sound("items/sword_charge")
    end)

end

function state:on_movement_changed(movement)
  local entity=state:get_entity()
  tunic_sprite = entity:get_sprite("tunic")
  sword_sprite = entity:get_sprite("sword")
  if movement.get_speed and movement:get_speed()>0 then
    tunic_sprite:set_animation("sword_loading_walking")
    sword_sprite:set_animation("sword_loading_walking")   
  else
    tunic_sprite:set_animation("sword_loading_stopped")
    sword_sprite:set_animation("sword_loading_stopped")
  end
end

function state:on_command_released(command)
  if command=="attack" then
    jump_manager.trigger_event(state:get_entity(), "attack command released")  
    return true
  end
end

function state:on_finished()
  sword_sprite:stop_animation()
  stars_sprite:stop_animation()
end

return function(_jump_manager)
  jump_manager=_jump_manager
end