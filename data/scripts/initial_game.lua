-- This script initializes game values for a new savegame file.
-- You should modify the initialize_new_savegame() function below
-- to set values like the initial life and equipment
-- as well as the starting location.
--
-- Usage:
-- local initial_game = require("scripts/initial_game")
-- initial_game:initialize_new_savegame(game)

local initial_game = {}
local maze_paths=require("scripts/maps/lib/windfish_maze_config")

-- Sets initial values to a new savegame file.
function initial_game:initialize_new_savegame(game)

  -- Initially give 3 hearts, the first tunic and the first wallet.
  game:set_max_life(12)
  game:set_life(game:get_max_life())
  game:get_item("tunic"):set_variant(1)
  game:get_item("rupee_bag"):set_variant(1)
  game:set_value("main_quest_step", 0)
  game:set_starting_location("houses/mabe_village/marin_house", "start_position")
  game:set_value("windfish_maze_boss_path_index", math.random(#maze_paths))
 --game:set_starting_location("examples/test_map", "destination")
end

return initial_game
