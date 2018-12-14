-- Variables
local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Include scripts
require("scripts/multi_events")

-- Event called when the custom entity is initialized.
entity:register_event("on_created", function()

  entity:set_can_traverse("hero", false)
  -- Movement
  local movement = sol.movement.create("random")
  movement:set_speed(20)
  movement:set_smooth(false)
  movement:set_max_distance(10)
  movement:start(entity)

end)