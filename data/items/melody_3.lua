-- Lua script of item "melody 3".
-- This script is executed only once for the whole game.

-- Variables
local item = ...
local game = item:get_game()

-- Event called when the game is initialized.
function item:on_created()

  item:set_savegame_variable("possession_melody_3")
  item:set_assignable(true)

end

-- Event called when the hero is using this item.
function item:on_using()

  local map = game:get_map()
  local hero = map:get_hero()
  local ocarina = game:get_item("ocarina")
  hero:freeze()
  game:set_pause_allowed(false)
  ocarina:playing_song("items/ocarina_3", function()
      hero:unfreeze()
      game:set_pause_allowed(true)
  end)

  item:set_finished()
  
end
