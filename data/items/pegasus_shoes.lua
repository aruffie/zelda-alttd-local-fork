local item = ...

require("scripts/multi_events")
require("scripts/states/run")

function item:on_created()

  self:set_savegame_variable("possession_pegasus_shoes")
  self:set_sound_when_brandished("treasure_2")
  self:set_assignable(true)
  -- Redefine event game.on_command_pressed.
  local game = self:get_game()
  game:set_ability("jump_over_water", 0) -- Disable auto-jump on water border.
  game:register_event("on_command_pressed", function(self, command)
    if not game:is_suspended() then
      local item = game:get_item("pegasus_shoes")
      local hero = game:get_hero()
      local effect = game:get_command_effect(command)
      local boots_possession = item:get_variant() > 0
      local slot = ((effect == "use_item_1") and 1)
          or ((effect == "use_item_2") and 2)
      local is_using_boots_action = boots_possession and command == "action"
                                      and game:get_command_effect("action") == "run"
      local is_using_boots_item = slot and game:get_item_assigned(slot) == item
      if is_using_boots_action or is_using_boots_item then
        hero:start_running_stopped(command) -- Call custom run script.
        return true
      end
    end
  end)
end

function item:on_variant_changed(variant)

  self:get_game():set_ability("run", variant)
end
