-- Configuration of the shop manager.
-- Feel free to change these values.

return {
  shovel = {
    price = 200,
    quantity = 1,
    placeholder = 1,
    variant = 1,
    dialog_id = "shovel",
    activation_condition = function(map)
      local item_shovel = map:get_game():get_item("shovel")
      local variant_shovel = item_shovel:get_variant()
      return variant_shovel == 0
    end
  },
  bomb = {
    price = 10,
    quantity = 10,
    placeholder = 1,
    variant = 1,
    dialog_id = "bomb",
    activation_condition = function(map)
      local item_shovel = map:get_game():get_item("shovel")
      local variant_shovel = item_shovel:get_variant()
      return variant_shovel > 0
    end
  },
  heart = {
    price = 10,
    quantity = 3,
    placeholder = 2,
    variant = 1,
    dialog_id = "heart",
    activation_condition = function(map)
      return true
    end
  },
  shield = {
    price = 50,
    quantity = 1,
    placeholder = 3,
    variant = 1,
    dialog_id = "shield",
    activation_condition = function(map)
      return true
    end
  }
}