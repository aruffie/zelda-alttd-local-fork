local sword_manager={}
local jump_manager=require("scripts/maps/jump_manager")

require("scripts/states/sword_swinging")(sword_manager)
require("scripts/states/sword_loading")(sword_manager)
require("scripts/states/sword_spin_attack")(sword_manager)
require("scripts/states/sword_tapping")(sword_manager)

function sword_manager.trigger_event(entity, event)
  local state, state_object=entity:get_state()
  debug_print ("state "..state.."("..(state_object and state_object.get_description and state_object:get_description() or "<built-in>")..") triggered the following Event: "..event)
  local desc=state_object and state_object.get_description and state_object:get_description() or ""
  sol.timer.start(entity, 10, function()
      if event=="jump complete" then --propagate jump ending event to jump manager
        jump_manager:trigger_event(entity, event)
      elseif event=="attack command released" then
        if desc=="sword_loading" or desc=="sword_tapping" then
          if entity.sword_loaded then
            debug_print "SPIN ATTACK"
            entity:sword_spin_attack()
          elseif entity:is_jumping() then
            entity:jump()
          else
            entity:unfreeze()
          end
          entity.sword_loaded=nil
        end
      elseif event=="sword swinging complete" then
        if entity:get_game():is_command_pressed("attack") then
          entity:sword_loading()
        else
          entity:unfreeze()
        end
      elseif event=="sword spin attack complete" then
        if entity:is_jumping() then
          entity:jump()
        else
          entity:unfreeze()
        end
      elseif event=="sword tapping" then
        entity:sword_tapping()
      elseif event=="sword tapping over" then
        entity:sword_loading()
      else --default case
        debug_print ("unknown event: "..event)
        entity:unfreeze()
      end
    end)
end

return sword_manager

