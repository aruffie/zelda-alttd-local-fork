----------------------------------
--
-- Monkey.
--
-- Immobile enemy throwing coconuts the hero, and occasionnaly a bomb.
-- One can start_knocking_off() the enemy manually from outside this script, to make him fall and run away.
--
-- Methods : enemy:start_throwing_projectile(direction, angle, [on_throwed_callback])
--           enemy:attack()
--           enemy:wait()
--           enemy:start_knocking_off()
--           enemy:start_running_away()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local circle = math.pi * 2.0
local is_knocked_off = false

-- Configuration variables
local waiting_duration = 2000
local second_thow_delay = 200
local bomb_probability = 0.1
local falling_duration = 600
local falling_height = 16
local falling_angle = 3 * quarter - 0.4
local falling_speed = 100
local running_speed = 100

local throwing_speed = 150
local throwing_duration = 600
local throwing_height = 12
local bounce_duration = 600
local coconut_bounce_number = 4
local coconut_bounce_height = 12
local coconut_bounce_minimum_speed = 40
local coconut_bounce_maximum_speed = 80
local bomb_bounce_number = 2
local bomb_bounce_height = 4
local bomb_bounce_speed = 40

-- Start a new bounce or call on_bounce_finished() if maximum bounce reached.
local function bounce(enemy, maximum_bounce, height, angle, minimum_speed, maximum_speed, on_bounce_finished)

  enemy.bounce_count = (enemy.bounce_count or 0) + 1
  if enemy.bounce_count < maximum_bounce then
    local movement = enemy:start_jumping(bounce_duration, height, angle or math.random() * circle, math.random(minimum_speed, maximum_speed), function()
      bounce(enemy, maximum_bounce, height, angle, minimum_speed, maximum_speed, on_bounce_finished)
    end)
    movement:set_ignore_obstacles(true)
  else
    if on_bounce_finished then
      on_bounce_finished()
    end
  end
end

-- Start throwing animation and create a coconut or bomb enemy when finished.
function enemy:start_throwing_projectile(direction, angle, on_throwed_callback)

  sprite:set_direction(direction)
  sprite:set_animation("throwing", function()
    local projectile_breed = math.random() > bomb_probability and "coconut" or "bomb" -- Throw a bomb once in a while.
    local projectile = enemy:create_enemy({
      name = (enemy:get_name() or enemy:get_breed()) .. "_" .. projectile_breed,
      breed = "projectiles/" .. projectile_breed
    })
    if projectile and projectile:exists() then -- If the projectile was not immediatly removed from the on_created() event.
      local movement = enemy:start_throwing(projectile, throwing_duration, 0, throwing_height, angle, throwing_speed, function()

        -- Bounce on throw finished.
        if projectile_breed == "coconut" then
          bounce(projectile, coconut_bounce_number, coconut_bounce_height, nil, coconut_bounce_minimum_speed, coconut_bounce_maximum_speed, function()
            projectile:destroy()
          end)
        else
          bounce(projectile, bomb_bounce_number, bomb_bounce_height, angle, bomb_bounce_speed, bomb_bounce_speed)
        end
      end)
      movement:set_ignore_obstacles(true)
    end

    sprite:set_animation("walking")
    if on_throwed_callback then
      on_throwed_callback()
    end
  end)
end

-- Throw two coconuts.
function enemy:attack()
 
  enemy:start_throwing_projectile(0, 3.0 * quarter + 0.5, function()
    attacking_timer = sol.timer.start(enemy, second_thow_delay, function()
      if not is_knocked_off then
        enemy:start_throwing_projectile(2, 3.0 * quarter - 0.5, function()
          enemy:wait()
        end)
      end
    end)
  end)
end

-- Wait a delay and start attacking.
function enemy:wait()

  sprite:set_animation("walking")
  sol.timer.start(enemy, waiting_duration, function()
    if not is_knocked_off then
      enemy:attack()
    end
  end)
end

-- Make the enemy knock off and run away.
function enemy:start_knocking_off()

  is_knocked_off = true
  enemy:start_jumping(falling_duration, falling_height, falling_angle, falling_speed, function()
    enemy:start_running_away()
  end)
  sprite:set_animation("falling")
end

-- Start runing away after falling down.
function enemy:start_running_away()

  sol.timer.start(enemy, waiting_duration, function()
    local direction = math.random(4)
    local movement = enemy:start_straight_walking(direction * quarter, running_speed)
    sprite:set_animation("escape")

    -- Remove the enemy once out of screen.
    movement:set_ignore_obstacles(true)
    function movement:on_position_changed()
      if not camera:overlaps(enemy:get_max_bounding_box()) then
        enemy:silent_kill()
      end
    end
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_invincible(true)

  -- States.
  sprite:set_xy(0, 0)
  enemy:set_obstacle_behavior("normal")
  enemy:set_damage(0)
  enemy:set_can_attack(false)
  enemy:wait()
end)