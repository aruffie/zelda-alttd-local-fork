-- Lua script of item "boomerang".
-- This script is executed only once for the whole game.

-- Variables
local item = ...

-- Event called when the game is initialized.
function item:on_created()

  self:set_savegame_variable("possession_boomerang")
  self:set_assignable(true)

end

-- Event called when the hero is using this item.
function item:start_using()

  local hero = self:get_map():get_entity("hero")
  if self:get_variant() == 1 then
    hero:start_boomerang(128, 160, "boomerang1", "entities/boomerang1")
  else
    hero:start_boomerang(192, 320, "boomerang2", "entities/boomerang2")
  end
  self:set_finished()

end

