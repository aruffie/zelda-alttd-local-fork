--[[
  Top-view custom jump with sword pulled out.

  To use, simply require this file into your jump-enabling item script, then call hero:start_jumping()
  Note, this script only handles (for now?) jumping with the sword being simultaneously being used (unless the item scripts handles this case on it's own).
  Don't forget to require "states/jumping" along this file so you can jump with bare hands too.

  This script is mostly a wrapper, all this does is setup the custom state and pass it to the jump manager system, who will actually do the animation.
--]]

local jm=require("scripts/jump_manager")
local audio_manager=require("scripts/audio_manager")
local state = jm.init("jumping_sword")

local hero_meta= sol.main.get_metatable("hero")
local sword_sprite
local tunic_sprite

--this is the function that starts it all
function hero_meta.start_flying_attack(hero)
  --print "attack on air !"
  if hero:get_state()~="custom" or hero:get_state_object():get_description()~="jumping_sword" then
    hero:start_state(state)
  end
  jm.start(hero, nil, function()
      if hero:get_ground_below() == "shallow_water" then
        audio_manager:play_sound("hero/wade1")
      elseif hero:get_ground_below()=="grass" then
        audio_manager:play_sound("hero/walk on grass")
      else
        audio_manager:play_sound("hero/land")
      end
    end)
end


function state:on_started(old_state_name, old_state_object)
--print "flying attaaaaack"
  local entity=state:get_entity()
  local game = state:get_game()
  local ability = game:get_ability("sword") --Should be at least 1 if your jump-enabling item script has checked this before starting this state 

  --Set up sprites
  tunic_sprite = entity:get_sprite("tunic")
  sword_sprite = entity:get_sprite("sword")
  sword_sprite:set_direction(tunic_sprite:get_direction())

  if old_state_name == "sword swinging" or old_state_name == "custom" and old_state_object:get_description() =="jumping" then
    tunic_sprite:set_animation("sword", function()
        --print "tunic attack finished"
        tunic_sprite:set_animation("sword_loading_stopped")
        sword_sprite:set_animation("sword_loading_stopped")
      end)
    sword_sprite:set_animation("sword")
--      , function()
--        print "sword attack finished"
--        sword_sprite:set_animation("sword_loading_stopped")
--      end)
  elseif old_state_name == "sword loading" then --Using explicit check instead of using only else in case the previous state was erroneous
    tunic_sprite:set_animation("sword_loading_stopped")
    sword_sprite:set_animation("sword_loading_stopped")
  end
end

function state:on_command_released(command)
  local entity=state:get_entity()
  if command =="attack" then
    if entity:is_jumping() then
      entity:jump()
    else
      tunic_sprite = entity:get_sprite("tunic")
      tunic_sprite:set_animation("stopped")

      entity:unfreeze()
    end
    return true
  end
end

function state:on_finished()
  sword_sprite:stop_animation()
  sword_sprite = nil
end