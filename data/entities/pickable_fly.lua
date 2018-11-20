-- Lua script of custom entity heart_fly.
-- This script is executed every time a custom entity with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local shadow
local sprite
local sprite_shadow

-- Event called when the custom entity is initialized.
function entity:on_created()

  entity:set_layer_independent_collisions(true)
  local x,y,layer = entity:get_position()
  shadow = map:create_custom_entity{
    x = x,
    y = y,
    width = 16,
    height = 8,
    direction = 0,
    layer = 0 ,
    sprite= "entities/heart_fly_shadow"
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

end

function entity:on_removed()
  shadow:remove()
end


function entity:on_picked()
  local sprite_name = entity:get_sprite():get_animation_set()
  -- Heart item.
  if sprite_name == "entities/heart_fly" then
    if game:get_life() == game:get_max_life() then
      audio_manager:play_sound("picked_item")
    else
     game:add_life(4)
    end
  -- Bomb item.
  elseif sprite_name == "entities/bomb_fly" then
    if bombs_counter:get_amount() == bombs_counter:get_max_amount() then
      audio_manager:play_sound("picked_item")
    else
      game:get_item("bombs_counter"):add_amount(1)
    end

  -- TODO: add more flying items here.

  end
end