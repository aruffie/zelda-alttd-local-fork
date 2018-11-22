-- Initialize destructible behavior specific to this quest.

-- Variables
local destructible_meta = sol.main.get_metatable("destructible")

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function destructible_meta:on_created(game)
    
  local directory = audio_manager:get_directory()
  if self:get_can_be_cut() then
    self:set_destruction_sound(directory .. "/others/bush_cut")
  else
    self:set_destruction_sound(directory .. "/others/rock_shatter")
  end
    
end