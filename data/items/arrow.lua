-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function item:on_created()

  item:set_shadow("small")
  item:set_can_disappear(true)
  item:set_brandish_when_picked(false)
  item:set_sound_when_picked(nil)
  
end

function item:on_started()

  -- Disable pickable arrows if the player has no bow.
  -- We cannot do this from on_created() because we don't know if the bow
  -- is already created there.
  item:set_obtainable(self:get_game():has_item("bow"))

end

function item:on_obtaining(variant, savegame_variable)

  -- Sound
  audio_manager:play_sound("items/get_item")
  -- Obtaining arrows increases the counter of the bow.
  local amounts = {1, 5, 10}
  local amount = amounts[variant]
  if amount == nil then
    error("Invalid variant '" .. variant .. "' for item 'arrow'")
  end
  item:get_game():get_item("bow"):add_amount(amount)

end