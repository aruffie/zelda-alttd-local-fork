-- Tunic
local item = ...

function item:on_created()

  self:set_savegame_variable("possession_tunic")

end

function item:on_obtained(variant, savegame_variable)

  -- Give the built-in ability "tunic", but only after the treasure sequence is done.
  self:get_game():set_ability("tunic", variant)

end

function item:on_obtaining(variant)

  -- Blue tunic: increase the defense; Red tunic : increase the force
  local game = item:get_game()
  local map = game:get_map()
  local force = game:get_value("force")
  local defense = game:get_value("defense")
  if variant == 2 then
    defense = defense + 1
    sol.audio.play_sound("treasure")
  elseif variant == 3 then
    force = force + 1
  end
  game:set_value("defense", defense)
  game:set_value("force",force)
end