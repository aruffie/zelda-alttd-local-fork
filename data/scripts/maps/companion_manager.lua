local companion_manager = {}
local game_meta = sol.main.get_metatable("game")
require("scripts/multi_events")


game_meta:register_event("on_map_changed", function(game, map)
    local hero = map:get_hero()
    local x_hero, y_hero, layer_hero = hero:get_position()
    local companions = require("scripts/maps/lib/companion_config.lua")
    -- We go through the list of companions
    for name, params in pairs(companions) do
        -- If the quest condition is true, create the companion.
        if params.activation_condition ~= nil and params:activation_condition(map) then
            map:create_custom_entity({
                name = "companion_" .. name,
                sprite = params.sprite,
                x = x_hero,
                y = y_hero,
                width = 16,
                height = 16,
                layer = layer_hero,
                direction = 0,
                model =  "follower"
              })
        end
    end
end)