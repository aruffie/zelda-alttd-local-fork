-- Variables
local map = ...
local game = map:get_game()

-- Map events
function map:on_started()

  map:set_digging_allowed(true)

end