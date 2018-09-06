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
            local destination_name = self:get_destination_name()
            local x_teletransporter, y_teletransporter = self:get_position()
            local effect_model = require("scripts/gfx_effects/" .. effect)
            -- Execute In effect
            effect_model.start_effect(surface, game, "in", false, function()
                if destination_name == "_side" then
                 local w_map, h_map = map:get_size()
                 -- We calculate the direction according to the position of the teletransporter on the map
                 local side = 0
                 if y_teletransporter == h_map then
                    side = 1
                 elseif x_teletransporter == w_map then
                    side = 2
                 elseif y_teletransporter == -16 then
                    side = 3
                 end
                 hero:teleport(destination_map, "_side" .. side, "immediate")
                 game.map_in_transition = effect_model
                elseif destination_map ~= map:get_id() then
                    hero:teleport(destination_map, destination_name, "immediate")
                    game.map_in_transition = effect_model
                else
                    hero:teleport(destination_map, destination_name, "immediate")
                    effect_model.start_effect(surface, game, "out")
                end

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