-- Defines the menus displayed when executing the quest,
-- before starting a game.

-- You can edit this file to add, remove or move some pre-game menus.
-- Each element must be the name of a menu script.
-- The last menu is supposed to start a game.

local initial_menus = {
  "scripts/menus/solarus_logo",
  --"scripts/menus/zeldaforce_logo",
  "scripts/menus/team_logo",
  "scripts/menus/language",
  "scripts/menus/copyright_menu",
  "scripts/menus/title_screen/title",
}

return initial_menus
