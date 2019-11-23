-- Lua script of enemy maskass.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local hero_movement

-- Only hurt if enemy and hero directions are opposite and not looking to each other.
local function on_sword_attack_received()

  local enemy_direction = sprite:get_direction()
  if enemy_direction == (hero:get_sprite():get_direction() + 2) % 4 and enemy_direction == hero:get_direction4_to(enemy) then
    enemy:hurt(2)
  end
end

-- Copy and reverse the given movement.
local function reverse_move(movement)
  local speed = movement:get_speed()
  if hero:get_state() ~= "hurt" and speed > 0 and enemy:get_life() > 0 then
    enemy:start_straight_walking(movement:get_angle() + math.pi, speed)
    sprite:set_direction((hero:get_sprite():get_direction() + 2) % 4) -- Always keep the hero opposite direction.
  else
    enemy:restart() -- Stop enemy.
  end
end

-- Copy and reverse hero moves.
hero:register_event("on_position_changed", function(hero)

  if not enemy:exists() or not enemy:is_enabled() then
    return
  end

  local movement = hero:get_movement()
  if movement ~= hero_movement then

    hero_movement = movement
    enemy:stop_movement()
    reverse_move(movement)
    movement:register_event("on_obstacle_reached", function(movement)
      enemy:restart()
    end)
    movement:register_event("on_changed", function(movement)
      reverse_move(movement)
    end)
  end
end)

-- Stop the movement if the hero don't have one anymore.
enemy:register_event("on_update", function(enemy)

  if enemy:get_movement() and not hero:get_movement() then
    enemy:restart()
  end
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(2, {
    arrow = 1,
    sword = on_sword_attack_received,
    hookshot = "immobilized",
    jump_on = "ignored"})

  -- States.
  sprite:set_animation("immobilized")
  enemy:stop_movement()
  enemy:set_can_attack(true)
  enemy:set_damage(2)
end)
