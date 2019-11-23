-- Lua script of custom entity spike_sideview.

-- Very experimental, aims to go along the built-in prickles ground, but without the automatic respawn when getting in contact with them

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()

  -- Initialize the properties of your custom entity here,
  -- like the sprite, the size, and whether it can traverse other
  -- entities and be traversed by them.
end

entity:add_collision_test("touching", function(entity, other)

    if other:get_type()=="hero" then --hurt the hero ad make it bounce up on contact
      other.vspeed=-4
      if not other:is_invincible() then
        entity:get_game():remove_life(2)
        other:set_invincible(true, 500)
      end
    end
  end)