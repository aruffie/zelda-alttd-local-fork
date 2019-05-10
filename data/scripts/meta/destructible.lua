-- Initialize destructible behavior specific to this quest.

-- Variables
local destructible_meta = sol.main.get_metatable("destructible")

-- Include scripts
local audio_manager = require("scripts/audio_manager")

function destructible_meta:on_created(game)
    
  local directory = audio_manager:get_directory()
  if self:get_can_be_cut() then
    self:set_destruction_sound(directory .. "/misc/bush_cut") -- Todo
  else
    self:set_destruction_sound(directory .. "/misc/rock_shatter") -- Todo
  end
    
end

function destructible_meta:on_looked()

  -- Here, self is the destructible object.
  local game = self:get_game()
  local sprite = self:get_sprite()
  if self:get_can_be_cut() == false then
    if not game:has_ability("lift") then
      game:start_dialog("_cannot_lift_too_heavy");
    else
      game:start_dialog("_cannot_lift_still_too_heavy");
    end
  end
  
end

function destructible_meta:is_hookable()

  local ground = self:get_modified_ground()
  if ground == "traversable" or
      ground == "grass" then
    return false
  end
  
  return true
end