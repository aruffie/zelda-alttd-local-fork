local teletransporter_manager = {}
require("scripts/multi_events")

local game_meta = sol.main.get_metatable("game")

game_meta:register_event("on_map_changed", function(game, map)
    local camera = map:get_camera()
    local surface = camera:get_surface()
    local hero = map:get_hero()
    -- Browse all teletransporters
    for teletransporter in map:get_entities_by_type("teletransporter") do
      local effect = teletransporter:get_property("effect")
      if effect ~= nil then
        function teletransporter:on_activated()
            self:set_enabled(false)
            local destination_map = self:get_destination_map()
            local effect_entity = require("scripts/gfx_effects/" .. effect)
            effect_entity.start_effect(surface, game, "in", false, function()
              hero:teleport(destination_map, "_side0", "immediate")
              effect_entity.start_effect(surface, game, "out")
            end)
        end
      end
    end

end)

return teletransporter_manager