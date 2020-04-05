-- Lua script of enemy ballchain_solider.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local ballchain

-- Configuration variables
local right_hand_offset_x = -8
local right_hand_offset_y = -19
local throwed_origin_chain_offset_x = 1
local throwed_origin_chain_offset_y = 17
local walking_speed = 16
local attack_triggering_distance = 80

-- Start the enemy movement.
function enemy:start_walking()

  local movement = enemy:start_target_walking(hero, walking_speed)

  function movement:on_position_changed()
    if enemy:is_near(hero, attack_triggering_distance) then
      enemy:start_attacking()
    end
  end

  sprite:set_animation("walking")
end

-- Start the enemy attack.
function enemy:start_attacking()

  enemy:stop_movement()
  sprite:set_animation("aiming")

  local function on_throwed_callback()
    sprite:set_animation("throwed")
    ballchain:set_chain_origin_offset(throwed_origin_chain_offset_x, throwed_origin_chain_offset_y)
  end
  local function on_takeback_callback()
    enemy:restart()
  end

  ballchain:start_attacking(on_throwed_callback, on_takeback_callback)
end

-- Reset the ballchain on hurt.
enemy:register_event("on_hurt", function(enemy)
  ballchain:restart()
end)

-- Remove the ballchain on dead.
enemy:register_event("on_dead", function(enemy)
  ballchain:silent_kill()
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(8)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)

  -- Create the ballchain.
  ballchain = enemy:create_enemy({
    name = (enemy:get_name() or enemy:get_breed()) .. "_ballchain",
    breed = "boss/projectiles/ballchain",
    direction = 2,
    x = right_hand_offset_x,
    y = right_hand_offset_y,
    layer = enemy:get_layer() + 1
  })
  enemy:start_welding(ballchain, right_hand_offset_x, right_hand_offset_y)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(4, {
    sword = 1,
    jump_on = "ignored"
  })

  -- States.
  ballchain:set_chain_origin_offset(0, 0)
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  enemy:start_walking()
end)
