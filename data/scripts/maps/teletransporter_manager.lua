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
            local effect_model = require("scripts/gfx_effects/" .. effect)
            -- Execute In effect
            effect_model.start_effect(surface, game, "in", false, function()
              local direction = hero:get_direction()
              direction = direction + 2
              if direction >= 4 then
                direction = direction - 4
              end
              hero:teleport(destination_map, "_side" .. direction, "immediate")
              game.map_in_transition = effect_model

            end)
        end
      end
    end
    -- Execute Out effect
   if game.map_in_transition ~= nil then
    game.map_in_transition.start_effect(surface, game, "out")
    game.map_in_transition = nil
   end

end)

return teletransporter_manager