local shop_manager = {}
local language_manager = require("scripts/language_manager")

function shop_manager:init(map)

  local game = map:get_game()
  local hero = map:get_hero()
  local shop_products = require("scripts/maps/lib/shop_config.lua")
  --local font = language_manager:get_menu_font(id)
  --local font_number = language_manager:get_menu_font(id)
    -- We go through the list of products
  for name, params in pairs(shop_products) do
    -- If the quest condition is true, create the product.
    shop_manager:add_product(map, name, params)
    
  end
  
  -- Events
  map:register_event("on_command_pressed", function(map, command)
    local hero = map:get_hero()
    if command == "attack" then -- Disable sword
      return true
    elseif command == "action" and shop_manager.product ~= nil then
      for k, product in pairs(shop_products) do
        local placeholder = map:get_entity("placeholder_" .. product.placeholder)
        local x_placeholder, y_placeholder = placeholder:get_position()
        local x_hero, y_hero = hero:get_position()
        if math.abs(y_placeholder - y_hero) < 48 and hero:get_direction() == 1 then
          if shop_manager.product.name == k then
            shop_manager.product.entity:remove()
            hero:unfreeze()
            shop_manager:add_product(map, shop_manager.product.name, shop_manager.product.params)
            shop_manager.product = nil
            return false
          end
        end
      end
      return true
    elseif command == "action" and hero:get_state() == "carrying" then
      --if hero:get_distance(merchant) <=16  or hero:get_distance(merchant_invisible) <=16  then
      --  local direction4 = merchant:get_direction4_to(hero)
      --  merchant:get_sprite():set_direction(direction4)
      --  shop_manager:buy_product(map, map.shop_manager_product)
      --end
    elseif (command == "up" or command == "down" or command == "left" or command == "right") and link_move == true then
      return true
    end

end)

end

function shop_manager:add_product(map, name, params)
  
  local game = map:get_game()
  if params.activation_condition ~= nil and params.activation_condition(map) then
      local placeholder = map:get_entity("placeholder_" .. params.placeholder)
      if placeholder ~= nil then
        local x_placeholder, y_placeholder, layer_placeholder = placeholder:get_position()
        -- Create product
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
        local product_lifting = map:create_custom_entity({
          name = "product_lifting_" .. name,
          sprite = "entities/" .. name,
          x = x_placeholder,
          y = y_placeholder + 24,
          width = 16,
          height = 16,
          layer = layer_placeholder,
          direction = 0
        })
        product_lifting:set_weight(0)
        product_lifting:bring_to_back()
        product_lifting:get_sprite():set_animation("invisible")
        function product_lifting:on_lifting()
          local sprite = product_lifting:get_sprite()
          print(product_lifting)
          shop_manager.product = {
            name = name,
            params = params,
            entity = product_lifting
          }
          product:remove()
          game:set_custom_command_effect("action", "none")
        end
        -- Create price and quantity
        local price_text = sol.text_surface.create({
          horizontal_alignment = "center",
          text = params.price
        })
        local quantity_text = nil
        if params.quantity > 1 then
          quantity_text = sol.text_surface.create({
            font = font_number,
            text = params.quantity,
            font_size = 8,
            color = {255,255,255}
          })
        end
        function product:on_pre_draw()
           map:draw_visual(price_text, x_placeholder, y_placeholder - 26)
           if quantity_text ~= nil then
            map:draw_visual(quantity_text, x_placeholder + 5, y_placeholder - 4)
           end
        end
      end  
    end
 end

return shop_manager