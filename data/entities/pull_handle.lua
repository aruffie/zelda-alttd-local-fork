-- A pull handle that can be pulled and come back to its inital place
-- Methods: set_maximum_moves()
-- Events: on_moving()

-- Custom entities that have the same name suffixed by "_chain" will follow the moves.
local pull_handle = ...
local game = pull_handle:get_game()
local map = pull_handle:get_map()

-- Include scripts
require("scripts/multi_events")

-- Event called when the custom entity is initialized.
pull_handle:register_event("on_created", function()

  pull_handle:set_traversable_by(false)
  pull_handle:set_drawn_in_y_order(true)
  pull_handle:set_weight(1)
end)

function pull_handle:on_interaction()

  -- Starts pulling state
end

--[[ hero:on_state_changing(state_name, next_state_name)

  if state_name == "pulling" then
    
    -- Making the pull handle comes to its initial place
  end
end ]]--