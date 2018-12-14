-- Variables
local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local chains_entities = {}

-- Include scripts
local chain_manager = require("scripts/maps/chain_manager")
require("scripts/multi_events")

-- Event called when the custom entity is initialized.
entity:register_event("on_created", function()
    
  entity:set_traversable_by(false)
  entity:set_can_traverse("hero", false)
  -- Movement
  local movement = sol.movement.create("random")
  movement:set_speed(20)
  movement:set_smooth(false)
  movement:set_max_distance(16)
  movement:start(entity)
  -- Chain
  local source = map:get_entity("chain_source")
  chain_manager:init_map(map, entity, source)

end)

