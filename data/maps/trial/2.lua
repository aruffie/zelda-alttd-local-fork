-- variables
local map = ...
local game = map:get_game()

-- Include scripts
local audio_manager = require("scripts/audio_manager")
local trial_manager = require("scripts/trial_manager")

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()

  -- Music
  audio_manager:play_music("21_mini_boss_battle")
  -- Trial
  trial_manager:init_map(map)

end
