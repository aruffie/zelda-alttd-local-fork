----------------------------------
--
-- Lakitu.
--
-- Flying enemy that always target the tangent of a radius over the hero, to turn over him.
-- Regularly throws spiked beetle on the floor.
--
----------------------------------

-- Global variables
local enemy = ...
local common_actions = require("enemies/lib/common_actions")
common_actions.learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local circle = math.pi * 2.0

-- Configuration variables
local flying_height = 16
local flying_speed = 60
local revolution_radius = 62
local between_throws_minimum_duration = 5000
local between_throws_maximum_duration = 7000
local ball_holding_duration = 800
local ball_throwing_duration = 900
local ball_throwing_height = 60

-- Get the angle to one of the tangent from the enemy to the hero circle.
local function get_tangent_angle(upper_tangent)

  local x, y = enemy:get_position()
  local hero_x, hero_y = hero:get_position()
  local dx = hero_x - x
  local dy = hero_y - y
  local distance = math.sqrt(dx * dx + dy * dy)

  if distance <= revolution_radius then -- Return nil if the enemy is inside the revolution radius.
    return nil 
  end

  local asin = math.asin(revolution_radius / distance)
  local atan2 = math.atan2(dy, dx)

  local tan_x, tan_y
  if upper_tangent then
    local t = atan2 + asin
    tan_x, tan_y = hero_x + revolution_radius * -math.sin(t), hero_y + revolution_radius * math.cos(t)
  else
    local t = atan2 - asin
    tan_x, tan_y = hero_x + revolution_radius * math.sin(t), hero_y + revolution_radius * -math.cos(t)
  end
  
  return math.atan2(y - tan_y, tan_x - x) -- Use atan2() instead of get_angle() to take care of decimal values of the tangent point.
end

-- Make the enemy throws a spiked ball.
local function start_throwing()

  local spiked_holding_height = flying_height + 20
  local ball_sprite = enemy:create_sprite("enemies/projectiles/spiked_ball")
  ball_sprite:set_xy(0, -spiked_holding_height)
  sprite:set_animation("holding")

  -- Hold the spiked ball for some time.
  sol.timer.start(enemy, ball_holding_duration, function()

    -- Check the layer below the enemy and wait for some time if the ball would be over obstacle on reaching the floor.
    local x, y, floor_layer = enemy:get_position()
    for layer = floor_layer, map:get_min_layer(), -1 do
      if map:get_ground(x, y, layer) ~= "empty" then
        floor_layer = layer
        break
      end
    end
    if enemy:test_obstacles(0, 0, floor_layer) then
      return 10
    end

    -- Create the throwed enemy.
    local spiked_ball = enemy:create_enemy({
      name = (enemy:get_name() or enemy:get_breed()) .. "_spiked_ball",
      breed = "empty", -- Workaround: Breed is mandatory but a non-existing one seems to be ok to create an empty enemy though.
      direction = 0,
      layer = floor_layer
    })
    common_actions.learn(spiked_ball)
    local spiked_sprite = spiked_ball:create_sprite("enemies/projectiles/spiked_ball")
    spiked_sprite:set_xy(0, -spiked_holding_height)
    spiked_ball:start_shadow()

    -- Throw the spiked ball and transform it on a spiked beetle on floor reached.
    enemy:start_throwing(spiked_ball, ball_throwing_duration, spiked_holding_height, ball_throwing_height, nil, nil, function()
      spiked_ball:create_enemy({
        name = (enemy:get_name() or enemy:get_breed()) .. "_spiked_beetle",
        breed = "spiked_beetle",
        direction = 0
      })
      spiked_ball:start_death()
    end)
    sprite:set_animation("throwing", function()
      sprite:set_animation("walking")
    end)
    enemy:remove_sprite(ball_sprite)
  end)
end

-- Make the enemy target the hero.
local function start_targetting()

  local upper_tangent = math.random(2) == 1
  local movement = enemy:start_straight_walking(get_tangent_angle(upper_tangent) or hero:get_angle(enemy), flying_speed)
  movement:set_ignore_obstacles()

  -- Correct the angle every frame to target the new tangent.
  local timer = sol.timer.start(enemy, 10, function()
    movement:set_angle(get_tangent_angle(upper_tangent) or movement:get_angle())

    -- Replace the enemy on the tangent point if the hero is moving closer.
    if enemy:get_distance(hero) < revolution_radius - 1 then
      local hero_x, hero_y = hero:get_position()
      local angle = hero:get_angle(enemy)
      enemy:set_position(hero_x + math.cos(angle) * revolution_radius, hero_y - math.sin(angle) * revolution_radius)
    end

    return true
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions({
  	arrow = 1,
  	boomerang = "immobilized",
  	explosion = 2,
  	sword = 1,
  	thrown_item = 2,
  	fire = 2,
  	jump_on = "ignored",
  	hammer = 2,
  	hookshot = "immobilized",
  	magic_powder = "ignored",
  	shield = "protected",
  	thrust = 2
  })

  -- States.
  sprite:set_xy(0, -flying_height)
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  start_targetting()
  sol.timer.start(enemy, math.random(between_throws_minimum_duration, between_throws_maximum_duration), function()
    start_throwing()
    return true
  end)
end)
