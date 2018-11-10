-- Variables
local map = ...
local game = map:get_game()

-- Map events
function map:on_started()

  map:set_digging_allowed(true)

end

--Doors events
function weak_door_1:on_opened()
  sol.audio.play_sound("secret_1")
end