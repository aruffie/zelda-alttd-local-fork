----------------------------------
--
-- Angler Fish.
--
-- Swimming enemy for sideview maps.
-- Starts by slowly moving up and down before charging horizontally.
-- Regularly call fry enemies and make 3 bricks fall from the ceiling when the wall is hit while charging.
--
-- Methods: enemy:start_waiting()
--
----------------------------------

-- Global variables.
local enemy = ...
local map_tools = require("scripts/maps/map_tools")
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local hurt_shader = sol.shader.create("hurt")
local quarter = math.pi * 0.5
local initial_position
local brick_position = 0
local is_hurt = false
local is_pushing_back = false

-- Configuration variables.
local waiting_speed = 40
local waiting_minimum_duration = 5000
local waiting_maximum_duration = 10000
local before_charging_duration = 500
local charging_speed = 240
local stunned_duration = 1000
local go_back_speed = 80
local between_fry_minimum_duration = 2000
local between_fry_maximum_duration = 10000
local between_bricks_duration = 800
local between_bricks_distance = 80
local hurt_duration = 600

-- Create a sub enemy with a position relative to the camera.
local function create_sub_enemy(name, breed, x, y)

  local camera_x, camera_y = camera:get_position()
  local sub_enemy = map:create_enemy({
    name = (enemy:get_name() or enemy:get_breed()) .. "_" .. name,
    breed = breed,
    x = camera_x + x,
    y = camera_y + y,
    layer = enemy:get_layer(),
    direction = 0
  })

  -- Echo some of the main enemy methods
  enemy:register_event("on_removed", function(enemy)
    if sub_enemy:exists() then
      sub_enemy:remove()
    end
  end)
  enemy:register_event("on_enabled", function(enemy)
    sub_enemy:set_enabled()
  end)
  enemy:register_event("on_disabled", function(enemy)
    sub_enemy:set_enabled(false)
  end)
  enemy:register_event("on_dead", function(enemy)
    if sub_enemy:exists() then
      sub_enemy:remove()
    end
  end)
end

-- Create a fry.
local function create_fry()

  local camera_width, camera_height = camera:get_size()
  create_sub_enemy("fry", "boss/projectiles/fry", math.random(2) == 1 and -7 or camera_width + 7, math.random(16, camera_height - 16))
end

-- Create a brick.
local function create_brick()

  local camera_width = camera:get_size()
  brick_position = (brick_position + between_bricks_distance) % camera_width
  create_sub_enemy("brick", "boss/projectiles/brick", brick_position, -2)
end

-- Check if the custom death as to be started before triggering the built-in hurt behavior.
local function hurt(damage)

  if is_hurt then
    return
  end
  is_hurt = true

  -- Custom die if no more life.
  if enemy:get_life() - damage < 1 then

    -- Wait a few time, start 2 sets of explosions close from the enemy, wait a few time again and finally make the final explosion and enemy die.
    enemy:start_death(function()
      sprite:set_shader(hurt_shader)
      sol.timer.start(enemy, 1500, function()
        enemy:start_close_explosions(32, 2500, "entities/explosion_boss", 0, -34, function()
          sol.timer.start(enemy, 1000, function()
            enemy:start_brief_effect("entities/explosion_boss", nil, 0, -34)
            finish_death()
          end)
        end)
        sol.timer.start(enemy, 200, function()
          enemy:start_close_explosions(32, 2300, "entities/explosion_boss", 0, -34)
        end)
      end)
    end)
    return
  end

  -- Else manually hurt to not trigger the built-in behavior and finish a possible movement.
  enemy:set_life(enemy:get_life() - damage)
  sprite:set_shader(hurt_shader)
  sol.timer.start(enemy, hurt_duration, function()
    is_hurt = false
    sprite:set_shader(nil)
  end)

  if enemy.on_hurt then
    enemy:on_hurt()
  end
end

-- Hurt and repulse the hero on sword attack received.
local function on_sword_attack_received()

  hurt(1)
  if not is_pushing_back then
    is_pushing_back = true
    enemy:start_pushing_back(hero, 150, 500, sprite, nil, function()
      is_pushing_back = false
    end)
  end
end

-- Start the enemy waiting movement.
local function start_waiting_movement(is_upwards)

  local movement = enemy:start_straight_walking(is_upwards and quarter or 3.0 * quarter, waiting_speed, nil, function()
    start_waiting_movement(not is_upwards)
  end)
end

-- Start the enemy charging movement.
local function start_charging()

  sol.timer.start(enemy, before_charging_duration, function()
    local movement = enemy:start_straight_walking(math.pi, charging_speed, nil, function()

      -- Start an earthquake and make 3 bricks fall.
      map_tools.start_earthquake({count = 12, amplitude = 4, speed = 90})
      local brick_count = 0
      sol.timer.start(enemy, between_bricks_duration, function()
        create_brick()
        brick_count = brick_count + 1
        return brick_count < 3
      end)

      -- Wait a few time then go back.
      sprite:set_animation("stopped")
      sol.timer.start(enemy, stunned_duration, function()
        enemy:start_straight_walking(0, go_back_speed, initial_position.x - enemy:get_position(), function()
          enemy:start_waiting()
        end)
        sprite:set_animation("walking")
      end)
    end)
    sprite:set_animation("charging")
  end)
end

-- Start waiting step before the charge.
function enemy:start_waiting()

  start_waiting_movement(math.random(2) == 1)

  -- Wait for some time then charge.
  sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    enemy:stop_movement()
    start_charging()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(10)
  enemy:set_size(60, 52)
  enemy:set_origin(30, 26)

  local x, y = enemy:get_position()
  initial_position = {x = x, y = y}
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions({
  	arrow = function() hurt(1) end,
  	boomerang = function() hurt(1) end,
  	explosion = function() hurt(4) end,
  	sword = on_sword_attack_received,
  	thrown_item = function() hurt(1) end,
  	fire = function() hurt(10) end,
  	jump_on = "ignored",
  	hammer = function() hurt(1) end,
  	hookshot = function() hurt(2) end,
  	magic_powder = "ignored",
  	shield = "protected",
  	thrust = function() hurt(1) end
  })

  -- States.
  enemy:set_drawn_in_y_order() -- Make sure sub enemies are drawn over the enemy.
  enemy:set_obstacle_behavior("flying")
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_can_attack(true)
  enemy:set_damage(6)
  enemy:start_waiting()

  -- Regularly call some fries.
  sol.timer.start(enemy, math.random(between_fry_minimum_duration, between_fry_maximum_duration), function()
    create_fry()
    return math.random(between_fry_minimum_duration, between_fry_maximum_duration)
  end)
end)
