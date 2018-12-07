-- Configuration of the shop manager.
-- Feel free to change these values.

return {
  shovel = {
    price = 200,
    quantity = 1,
    placeholder = 1,
    variant = 1,
    sprite = "entities/shovel",
    dialog_id = "shovel",
    buy_callback = function(map)
      local item = map:get_game():get_item("shovel")
      item:set_variant(1)
    end,  
    activation_condition = function(map)
      local item_shovel = map:get_game():get_item("shovel")
      local variant_shovel = item_shovel:get_variant()
      return variant_shovel == 0
    end
  },
  bombs = {
    price = 10,
    quantity = 10,
    placeholder = 4,
    variant = 1,
    sprite = "entities/bomb",
    dialog_id = "bomb",
    buy_callback = function(map)
      local item = map:get_game():get_item("bombs_counter")
      if item:get_variant() == 0 then
        item:set_max_amount(20)
      end  
      item:set_variant(1)
      item:add_amount(10)
    end,  
    activation_condition = function(map)
      local item_shovel = map:get_game():get_item("shovel")
      local variant_shovel = item_shovel:get_variant()
      return variant_shovel > 0
    end
  },
  bow = {
    price = 980,
    quantity = 1,
    placeholder = 1,
    variant = 1,
    sprite = "entities/bow",
    dialog_id = "bow",
    buy_callback = function(map)
      local item_bow = map:get_game():get_item("bow")
      local variant_bow = item_bow:get_variant()
      return variant_bow > 0
    end,  
    activation_condition = function(map)
      local item_bow = map:get_game():get_item("bow")
      local variant_bow = item_bow:get_variant()
      return variant_bow == 0
    end,  
  },
  heart = {
    price = 10,
    quantity = 3,
    placeholder = 2,
    variant = 1,
    sprite = "entities/items/heart",
    dialog_id = "heart",
    buy_callback = function(map)
      local game = map:get_game()
      game:add_life(12)
    end, 
    activation_condition = function(map)
      return true
    end
  },
  shield = {
    price = 50,
    quantity = 1,
    placeholder = 3,
    variant = 1,
    sprite = "entities/shield",
    dialog_id = "shield",
    buy_callback = function(map)
      local item = map:get_game():get_item("shield")
      item:set_variant(1)
    end, 
    activation_condition = function(map)
      return true
    end
  }
}