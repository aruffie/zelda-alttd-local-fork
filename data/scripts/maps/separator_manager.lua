-- This script restores entities when there are separators in a map.
-- When taking separators prefixed by "auto_separator", the following entities are restored:
-- - Enemies prefixed by "auto_enemy".
-- - Destructibles prefixed by "auto_destructible".
-- - Blocks prefixed by "auto_block".
-- And the following entities are destroyed:
-- - Bombs.

local separator_manager = {}
local light_manager_fsa = require("scripts/maps/light_manager")
require("scripts/multi_events")
local entity_respawn_manager=require("scripts/maps/entity_respawn_manager")

function separator_manager:init(map)
  if map:get_world()=="outside_world" then
    return
  end
  entity_respawn_manager:init(map)
  entity_respawn_manager:save_entities(map)
  -- Function called when a separator was just taken.
  local function separator_on_activated(separator)
    local hero=map:get_hero()
    entity_respawn_manager:respawn_enemies(map) -- originally triggered by separator:on_activating
    entity_respawn_manager:reset_torches(map)
    entity_respawn_manager:reset_bombs()

    hero.respawn_point_saved=nil
    -- Enemies.

  end

  -- Function called when a separator is being taken.
  local function separator_on_activating(separator) 
    entity_respawn_manager:reset_enemies(map) -- originally triggered by separator:on_activated
    entity_respawn_manager:reset_blocks(map)
    entity_respawn_manager:reset_custom_entities(map)
    entity_respawn_manager:reset_unstable_floors(map)
    entity_respawn_manager:reset_destructibles(map)
  end

  for separator in map:get_entities_by_type("separator") do
    separator:register_event("on_activating", separator_on_activating)
    separator:register_event("on_activated", separator_on_activated)
  end

end

return separator_manager

