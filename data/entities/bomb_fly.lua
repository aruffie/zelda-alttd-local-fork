-- Lua script of custom entity bomb_fly.
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

entity:add_collision_test("center", function(bomb, entity)
  if entity :get_type()== "hero" then
    local item = game:get_item("feather")
    local bombs_counter = game:get_item("bombs_counter")

    if item:is_jumping() then
      bomb:remove()
     if bombs_counter:get_amount() == bombs_counter:get_max_amount() then
        sol.audio.play_sound("picked_item")
      else
        game:get_item("bombs_counter"):add_amount(1)
      end
    else
    end
  end
end)

end

function entity:on_removed()
  shadow:remove()
end


