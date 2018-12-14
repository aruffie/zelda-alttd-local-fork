-- Variables
local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local shadow
local sprite
local sprite_shadow

-- Include scripts
require("scripts/multi_events")

-- Event called when the custom entity is initialized.
entity:register_event("on_created", function()

  entity:set_layer_independent_collisions(true)
  local x,y,layer = entity:get_position()
  shadow = map:create_custom_entity{
    x = x,
    y = y,
    width = 16,
    height = 8,
    direction = 0,
    layer = 0 ,
    sprite ="entities/shadows/pickable_flying"
  }
  sprite = entity:get_sprite()
  sprite_shadow = shadow:get_sprite()
  sprite:set_animation("normal")
  sprite_shadow:set_animation("normal")
  entity:add_collision_test("center", function(entity, other_entity)
    if other_entity:get_type()== "hero" and other_entity:is_jumping() then
      entity:on_picked()
      entity:remove()
    end
  end)

end)

entity:register_event("on_removed", function()
  
  shadow:remove()
  
end)

entity:register_event("on_picked", function()
  
  local sprite_name = entity:get_sprite():get_animation_set()
  -- Heart item.
  if sprite_name == "entities/items/heart_fly" then
    if game:get_life() == game:get_max_life() then
      audio_manager:play_sound("items/get_item")
    else
     game:add_life(4)
    end
  -- Bomb item.
  elseif sprite_name == "entities/items/bomb_fly" then
    if bombs_counter:get_amount() == bombs_counter:get_max_amount() then
      audio_manager:play_sound("items/get_item")
    else
      game:get_item("bombs_counter"):add_amount(1)
    end

  -- TODO: add more flying items here.

  end

end)