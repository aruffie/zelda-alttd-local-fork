local item = ...

require("scripts/multi_events")
require("scripts/ground_effects")
require("scripts/actions/jump")
local hero_meta = sol.main.get_metatable("hero")

-- Initialize parameters for custom jump.
local jump_duration = 430 -- Duration of jump in milliseconds.
local max_height_normal = 16 -- Default height, do NOT change!
local max_height_sideview = 20 -- Default height for sideview maps, do NOT change!
local max_height -- Height of jump in pixels.
local max_distance = 31 -- Max distance of jump in pixels.
local jumping_speed = math.floor(1000 * max_distance / jump_duration)
local disabled_entities -- Nearby streams and teletransporters that are disabled during the jump
local jumping_state -- Custom state for jumping.

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
    local item = game:get_item("feather")
    local hero = game:get_hero()
    local effect = game:get_command_effect(command)
    local slot = ((effect == "use_item_1") and 1)
        or ((effect == "use_item_2") and 2)
    if slot and game:get_item_assigned(slot) == item then
      if not hero:is_jumping() then
        hero:start_custom_jump() -- Call custom jump script.
      end
      return true
    end
  end)
end
