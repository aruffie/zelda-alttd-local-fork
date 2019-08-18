-- Lua script of enemy blue stalfos.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
local common_actions = require("enemies/lib/common_actions")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5

-- Configuration variables
local walking_possible_angle = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_distance_grid = 16
local walking_max_move_by_step = 6

local attack_triggering_distance = 64
local jumping_speed = 128
local jumping_height = 16
local jumping_duration = 600
local throwing_bone_delay = 200

-- Start a random straight movement of a random distance vertically or horizontally, and loop it without delay.
function enemy:start_walking()

  math.randomseed(sol.main.get_elapsed_time())
  enemy:start_random_walking(walking_possible_angle, walking_speed, walking_distance_grid * math.random(walking_max_move_by_step), function()
    enemy:start_walking()
  end)
end

-- Make the enemy move on the opposite of the hero.
function enemy:start_jumping_movement()

  -- Start the on-floor jumping movement.
  local enemy_x, enemy_y, _ = enemy:get_position()
  local hero_x, hero_y, _ = hero:get_position()
  local movement = sol.movement.create("straight")
  movement:set_speed(jumping_speed)
  movement:set_angle(math.atan2(hero_y - enemy_y, enemy_x - hero_x))
  movement:set_max_distance(jumping_speed * 0.001 * jumping_duration)
  movement:set_smooth(false)
  movement:start(enemy)
  sprite:set_animation("jumping")
end

-- Event triggered when the enemy is close enough to the hero.
function enemy:start_attacking()

  -- Start jumping away from the hero.
  enemy:start_jumping_movement()
  enemy:start_jumping(jumping_duration, true, jumping_height)
end

-- Start attacking when the hero is near enough and an attack or item command is pressed, even if not assigned to an item.
game:register_event("on_command_pressed", function(game, command)

  if enemy:exists() and enemy:is_enabled() then
    if enemy:is_near(hero, attack_triggering_distance) and (command == "attack" or command == "item_1" or command == "item_2") then
      enemy:start_attacking()
    end
  end
end)

-- Start walking again when the attack finished.
function enemy:on_jump_finished()
  enemy:restart()

  -- Throw a bone club at the hero after a delay.
  sol.timer.start(enemy, throwing_bone_delay, function()
    
    local x, y, layer = enemy:get_position()
    map:create_enemy({
      breed = "projectiles/bone",
      x = x,
      y = y,
      layer = layer,
      direction = enemy:get_direction4_to(hero)
    })
  end)
end

-- Initialization.
function enemy:on_created()

  common_actions.learn(enemy, sprite)
  enemy:set_life(3)
  enemy:add_shadow()
end

-- Restart settings.
function enemy:on_restarted()

  -- Behavior for each items.
  enemy:set_attack_consequence("sword", 1)
  enemy:set_attack_consequence("thrown_item", 2)
  enemy:set_attack_consequence("arrow", 2)
  enemy:set_attack_consequence("hookshot", 2)
  enemy:set_attack_consequence("fire", 2)
  enemy:set_attack_consequence("boomerang", 2)
  enemy:set_attack_consequence("explosion", 2)
  enemy:set_hammer_reaction(2)
  enemy:set_fire_reaction("protected")

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking()
end
