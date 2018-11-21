-- Variables
local item = ...

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function item:on_created()

  self:set_shadow("small")
  self:set_can_disappear(true)
  self:set_brandish_when_picked(false)
  self:set_sound_when_picked(nil)
  
end

function item:on_obtaining(variant, savegame_variable)

  audio_manager:play_sound("items/get_rupee")
  local amounts = {1, 5, 20, 50, 100, 200}
  local amount = amounts[variant]
  if amount == nil then
    error("Invalid variant '" .. variant .. "' for item 'rupee'")
  end
  self:get_game():add_money(amount)
end

