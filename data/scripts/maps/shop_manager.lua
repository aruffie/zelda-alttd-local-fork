local shop_manager = {}
local language_manager = require("scripts/language_manager")
local map

function shop_manager:init(map)

  local game = map:get_game()
  local hero = map:get_hero()
  local shop_products = require("scripts/maps/lib/shop_config.lua")
    -- We go through the list of companions
  for name, params in pairs(shop_products) do
    -- If the quest condition is true, create the companion.
    if params.activation_condition ~= nil and params.activation_condition(map) then
      local placeholder = map:get_entity("placeholder_" .. params.placeholder)
      if placeholder ~= nil then
        local x_placeholder, y_placeholder, layer_placeholder = placeholder:get_position()
        local product = map:create_custom_entity({
          name = "product_" .. name,
          sprite = "entities/" .. name,
          x = x_placeholder,
          y = y_placeholder,
          width = 16,
          height = 16,
          layer = layer_placeholder,
          direction = 0
        })
        product:set_traversable_by(false)
        product:set_weight(0)
      end  

    end
  end

end


return shop_manager