local item = ...

require("scripts/multi_events")
require("scripts/states/jump")
require("scripts/states/runjump")
function item:on_created()

  item:set_savegame_variable("possession_feather")
  item:set_sound_when_brandished("treasure_2")
  item:set_assignable(true)
  --[[ Redefine event game.on_command_pressed.
  -- Avoids restarting hero animation when feather command is pressed
  -- in the middle of a jump, and using weapons while jumping. --]]
  local game = self:get_game()
  game:set_ability("jump_over_water", 0) -- Disable auto-jump on water border.
  game:register_event("on_command_pressed", function(self, command)
    if game:is_suspended() then return end
    local item = game:get_item("feather")
    local hero = game:get_hero()
    local effect = game:get_command_effect(command)
    local slot = ((effect == "use_item_1") and 1)
        or ((effect == "use_item_2") and 2)
    if slot and game:get_item_assigned(slot) == item then
      if hero.is_running and hero:is_running() then
        hero:start_runjump() -- Call runjump script.
      else
        hero:start_custom_jump() -- Call custom jump script.
      end
      return true
    end
  end)
end
