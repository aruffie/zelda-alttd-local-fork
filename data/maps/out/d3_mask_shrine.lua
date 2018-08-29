-- Outside - Mask Shrine

-- Variables
local map = ...
local game = map:get_game()


-- Methods - Functions


-- Events

function map:on_started()

  map:set_digging_allowed(true)


end

--Weak doors play secret sound on opened
function weak_door_1:on_opened() sol.audio.play_sound("secret_1") end