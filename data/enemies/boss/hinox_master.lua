-- Lua script of enemy hinox master.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local is_throw_upcoming = false
local is_hero_catchable = true

-- Configuration variables
local waiting_duration = 500
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 32
local charging_speed = 128
local charging_maximum_distance = 100
local charging_probability = 0.5
local before_charging_delay  = 1000

local right_hand_offset_x = -24
local right_hand_offset_y = -50
local throwing_preparation_duration = 500
local bomb_throwing_duration = 800
local bomb_throwing_height = 60
local bomb_throwing_speed = 120
local hero_throwing_duration = 800
local hero_throwing_height = 60
local hero_throwing_speed = 240

-- Hold the given entity in the given hand and wait for the actual throw.
-- TODO Merge
local function start_preparing_throw(right_hand, before_restart_delay, on_throwing)

  is_throw_upcoming = false
  sprite:set_animation("throwing")
  sprite:set_direction(right_hand and 2 or 0)

  sol.timer.start(enemy, throwing_preparation_duration, function()
    on_throwing()
    sprite:set_direction(right_hand and 0 or 2)
    sol.timer.start(enemy, before_restart_delay, function()
      enemy:restart()
    end)
  end)
end

-- Start the enemy walking movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()

    -- At the end of the move, wait a few time then randomly charge or restart another move.
    sol.timer.start(enemy, waiting_duration, function()
      if math.random() > charging_probability then
        enemy:start_charging()
      else
        enemy:start_walking()
      end
    end)
  end)
end

-- Start the enemy charging movement.
function enemy:start_charging()

  sprite:set_animation("charge")
  sol.timer.start(enemy, before_charging_delay, function()
    enemy:start_straight_walking(enemy:get_angle(hero), charging_speed, charging_maximum_distance, function()
      enemy:restart()
    end)
    sprite:set_animation("charge")
    sprite:set_frame_delay(100)
  end)
end

-- Throw a bomb to the hero.
-- TODO Factorize.
function enemy:throw_bomb()

  is_hero_catchable = false
  enemy:stop_movement()
  sol.timer.stop_all(enemy)

  local x, y, layer = enemy:get_position()
  local hero_x, _ , hero_layer = hero:get_position()
  local is_right_hand_throw = hero_x > x
  local hand_offset_x = is_right_hand_throw and right_hand_offset_x or 0 - right_hand_offset_x

  -- Hold a bomb for some time and throw it.
  local bomb = enemy:create_enemy({
    breed = "projectiles/bomb",
    x = hand_offset_x
  })
  bomb:set_position(x + hand_offset_x, y, layer + 1) -- Layer + 1 to not interact with a possible ground after moved.
  bomb:get_sprite():set_xy(0, right_hand_offset_y)

  start_preparing_throw(is_right_hand_throw, throwing_preparation_duration, function()

    -- Start the thrown movement to the hero.
    local angle = bomb:get_angle(hero)
    enemy:start_throwing(bomb, bomb_throwing_duration, -right_hand_offset_y, bomb_throwing_height, angle, bomb_throwing_speed, function()
      is_hero_catchable = true
      bomb:set_layer(hero_layer)
      bomb:explode()
    end)
  end)
end

-- Throw the hero to the center of the room.
-- TODO Factorize.
function enemy:throw_hero()

  is_hero_catchable = false
  enemy:stop_movement()
  sol.timer.stop_all(enemy)

  local x, y, layer = enemy:get_position()
  local center_x = camera:get_position() + camera:get_size() / 2.0
  local is_right_hand_throw = center_x > x
  local hand_offset_x = is_right_hand_throw and right_hand_offset_x or 0 - right_hand_offset_x

  -- Freeze the hero and make it hold in the enemy hand.
  local hero_sprite = hero:get_sprite()
  hero:freeze()
  hero:set_position(x + hand_offset_x, y, layer + 1) -- Layer + 1 to not interact with a possible ground after moved.
  hero_sprite:set_xy(0, right_hand_offset_y)
  hero_sprite:set_animation("scared")
  start_preparing_throw(is_right_hand_throw, throwing_preparation_duration, function()

    -- Throw the hero to the center of the room.
    local camera_x, camera_y = camera:get_position()
    local camera_width, camera_height = camera:get_size()
    local angle = hero:get_angle(camera_x + camera_width / 2.0, camera_y + camera_height / 2.0)
    enemy:start_throwing(hero, hero_throwing_duration, -right_hand_offset_y, hero_throwing_height, angle, hero_throwing_speed, function()
      is_hero_catchable = true
      hero:unfreeze()
    end)
  end)
end

-- Catch the hero on attacking him.
enemy:register_event("on_attacking_hero", function(enemy, hero, enemy_sprite)

  if is_hero_catchable then
    enemy:throw_hero()
  end
end)

-- Prepare to throw a bomb on hurt.
enemy:register_event("on_hurt", function(enemy)
  is_throw_upcoming = true
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(8)
  enemy:set_size(64, 40) -- Workaround : Adapt the size to never have a part of enemy sprite under ceiling nor holded hero over a wall.
  enemy:set_origin(32, 37)
  enemy:set_hurt_style("boss")
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(4, {
    sword = 1,
    boomerang = 2,
    hookshot = 2,
    thrust = 2,
    jump_on = "ignored"
  })

  -- States.
  sprite:set_animation("waiting")
  enemy:set_damage(0)
  enemy:set_can_attack(true)
  enemy:set_obstacle_behavior("flying") -- Don't fall in holes.
  if is_throw_upcoming then
    enemy:throw_bomb()
  else
    sol.timer.start(enemy, waiting_duration, function()
      enemy:start_walking()
    end)
  end
end)
