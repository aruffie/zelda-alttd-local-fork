-- Lua script of enemy pokey.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local head_sprite
local body_sprites = {}
local quarter = math.pi * 0.5

-- Configuration variables
local life = 3
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    enemy:start_walking()
  end)
end

-- Detach the lowest body and make it bounce around the map.
function enemy:detach_body()

  -- Replace sprites position and detach a body if the body number is greater than the enemy life.
  for i = 1, #body_sprites do
    if i > enemy:get_life() - 2 then
      enemy:remove_sprite(body_sprites[i])
      body_sprites[i] = nil
    else
      body_sprites[i]:set_xy(0, -11 * (i - 1))
    end
  end
  head_sprite:set_xy(0, -11 * #body_sprites)

  -- TODO Create bouncing body entity.

  enemy:hurt(1)
end

-- Detach a body on weak attack received.
local function on_weak_attack_received()
  enemy:detach_body()
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(life)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()

  -- Create sprites.
  head_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  for i = 1, life - 1 do
    body_sprites[i] = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/body")
    enemy:bring_sprite_to_front(body_sprites[i])
  end
  enemy:bring_sprite_to_front(head_sprite)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(4, {
    sword = on_weak_attack_received,
    arrow = on_weak_attack_received,
    explosion = on_weak_attack_received,
    jump_on = "ignored"
  })

  -- Sprites.
  for i = 1, #body_sprites do
    body_sprites[i]:set_xy(0, -11 * (i - 1))
  end
  head_sprite:set_xy(0, -11 * #body_sprites)

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  enemy:start_walking()
end)
