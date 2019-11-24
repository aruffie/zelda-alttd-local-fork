local shop_manager = {}
local language_manager = require("scripts/language_manager")

-- Initialize the shop .
function shop_manager:init(map)
  local game = map:get_game()
  local hero = map:get_hero()
  local shop_products = require("scripts/maps/lib/shop_config")

  -- We go through the list of products
  for name, params in pairs(shop_products) do
    -- If the quest condition is true, create the product.
    shop_manager:add_product(map, name, params)
  end

  -- Events
  map:register_event("on_command_pressed", function(map, command)
    local hero = map:get_hero()
    if command == "attack" and shop_manager.product ~= nil then
      -- Disable sword when the hero is carrying a product.
      return true
    elseif command == "action" and shop_manager.product ~= nil then
      for k, product in pairs(shop_products) do
        local placeholder = map:get_entity("placeholder_" .. product.placeholder)
        local x_placeholder, y_placeholder = placeholder:get_position()
        local x_hero, y_hero = hero:get_position()
        if math.abs(y_placeholder - y_hero) < 48 and hero:get_direction() == 1 then
          if shop_manager.product.name == k then
            local carried_object = hero:get_carried_object()
            local state = sol.state.create()
            state:set_carried_object_action("remove")
            hero:start_state(state)
            hero:unfreeze()
            shop_manager:add_product(map, shop_manager.product.name, shop_manager.product.params)
            shop_manager.product = nil
            return false
          end
        end
      end
      local merchant = map:get_entity("merchant")
      local merchant_invisible = map:get_entity("merchant_invisible")
      if hero:get_distance(merchant) <=16  or hero:get_distance(merchant_invisible) <=16  then
        local direction4 = merchant:get_direction4_to(hero)
        merchant:get_sprite():set_direction(direction4)
        shop_manager:buy_product(map)
      end
      return true
    elseif (command == "up" or command == "down" or command == "left" or command == "right") and link_move == true then
      return true
    end
  end)
end

-- Add a product to the shop.
function shop_manager:add_product(map, name, params)
  local game = map:get_game()
  if params.activation_condition ~= nil and params.activation_condition(map) then
    local placeholder = map:get_entity("placeholder_" .. params.placeholder)

    if placeholder ~= nil then
      local x_placeholder, y_placeholder, layer_placeholder = placeholder:get_position()

      -- Create product.
      local product = map:create_custom_entity({
        name = "product_" .. name,
        sprite = params.sprite,
        x = x_placeholder,
        y = y_placeholder,
        width = 16,
        height = 16,
        layer = layer_placeholder,
        direction = 0
      })
      local product_price = map:create_custom_entity({
        name = "product_price_" .. name,
        sprite = 'entities/symbols/prices',
        x = x_placeholder,
        y = y_placeholder - 12,
        width = 16,
        height = 16,
        layer = layer_placeholder,
        direction = 0
      })
      product_price:get_sprite():set_animation(params.price)
      local product_lifting = map:create_custom_entity({
        name = "product_lifting_" .. name,
        sprite = params.sprite,
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
      function product_lifting:on_lifting(carrier, carried_object)
        local sprite = carried_object:get_sprite()
        sprite:set_animation("take")
        shop_manager.product = {
          name = name,
          params = params
        }
        product:remove()
        product_price:remove()
        --game:set_custom_command_effect("action", "buy")
      end
  
    end
  end
end

-- Buy a product to the shop.
function shop_manager:buy_product(map)
  if shop_manager.product == nil then
    return false
  end
  
  local game = map:get_game()
  local hero = map:get_hero()

  game:start_dialog("maps.houses.mabe_village.shop_2.product" .. "_" .. shop_manager.product.params.dialog_id, function(answer)
    if answer == 1 then
      local error = false
      -- Hearts
      if shop_manager.product.name == "heart" then
        if game:get_life() == game:get_max_life() then
          error = true
        end
      elseif shop_manager.product.name == "bombs" then
        local item = game:get_item("bombs_counter")
        if item:get_variant() > 0 and item:get_amount() >= item:get_max_amount() then
          error = true
        end
      elseif shop_manager.product.name == "arrow" then
        local item = game:get_item("bow")
        if item:get_amount() >= item:get_max_amount() then
          error = true
        end
      elseif shop_manager.product.name == "shield" then
        local item = game:get_item("shield")
        local variant = item:get_variant()
        if variant > 0 then
          error = true
        end
      end
      if error then
        game:start_dialog("maps.houses.mabe_village.shop_2.merchant_4")
      else
        local money = game:get_money()
        if money >= shop_manager.product.params.price then
          local carried_object = hero:get_carried_object()
          local state = sol.state.create()
          state:set_carried_object_action("remove")
          hero:start_state(state)
          hero:unfreeze()
          game:remove_money(shop_manager.product.params.price)
          shop_manager.product.params.buy_callback(map)
          game:start_dialog("maps.houses.mabe_village.shop_2.merchant_6")
          shop_manager.product = nil
        else
          game:start_dialog("maps.houses.mabe_village.shop_2.merchant_3")
        end
      end
    end
  end)
end

return shop_manager
