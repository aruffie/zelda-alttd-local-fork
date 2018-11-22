-- Variables
local item = ...
local game = item:get_game()

function item:on_created()

  self:set_savegame_variable("possession_tunic")
  
end

function item:on_obtaining(variant)

  -- Audio
  audio_manager:play_sound("items/fanfare_item_extended")
  -- Give the built-in ability "tunic", but only after the treasure sequence is done.
  game:set_ability("tunic", variant)
  -- Update force and defense for the tunic.
  local map = game:get_map()
  local force = game:get_value("force")
  local defense = game:get_value("defense")
  if variant == 1 then -- Green tunic.
    game:set_value("force_tunic", 1)
    game:set_value("defense_tunic", 1)  
  elseif variant == 2 then -- Blue tunic increases defense.
    game:set_value("force_tunic", 1)
    game:set_value("defense_tunic", 2)
  elseif variant == 3 then -- Red tunic increases force.    
    game:set_value("force_tunic", 2)
    game:set_value("defense_tunic", 1)
  end
  
end