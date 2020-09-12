----------------------------------
--
-- Cue Ball.
--
-- Charge to a direction 4 and turn right on obstacle reached.
-- Spin around himself on hurt, and 
--
-- Methods : enemy:start_charging([direction4])
--           enemy:start_spinning()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local hurt_frame_delay = sprite:get_frame_delay("hurt")
local quarter = math.pi * 0.5
local circle = math.pi * 2.0

-- Configuration variables
local charging_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local charging_speed = 120
local waiting_duration = 500
local spinning_minimum_duration = 500
local spinning_maximum_duration = 1000

-- Hurt if the enemy angle to hero is not on the circle the enemy is looking at. 
local function on_attack_received()

  -- Don't hurt if a previous hurt animation is still running.
  if sprite:get_animation() == "hurt" then
    return
  end

  -- Manually hurt the enemy to not restart it automatically and immediatly start spinning.
  local difference_angle = (sprite:get_direction() * quarter - enemy:get_angle(hero)) % circle
  if difference_angle >= quarter and difference_angle <= 3 * quarter  then
    enemy:set_life(enemy:get_life() - 1)
    enemy:start_spinning()
  else
    -- Repulse one pixel to the back if not hurt.
  end
end

-- Start the enemy movement.
function enemy:start_charging(direction4)

  direction4 = direction4 or sprite:get_direction()
  enemy:start_straight_walking(charging_angles[direction4 + 1], charging_speed, nil, function()
    sprite:set_animation("stopped")
    sol.timer.start(enemy, waiting_duration, function()
      enemy:start_charging((direction4 - 1) % 4)
    end)
  end)
end

-- Start spinning around himself for some time then start charging on the last direction of the spin.
function enemy:start_spinning()

  sprite:set_animation("hurt")
  sol.timer.stop_all(enemy)
  enemy:stop_movement()

  local spinning_timer = sol.timer.start(enemy, hurt_frame_delay, function()
    local frame = sprite:get_frame()
    sprite:set_direction((sprite:get_direction() - 1) % 4)
    sprite:set_frame(frame)
    return true
  end)
  sol.timer.start(enemy, math.random(spinning_minimum_duration, spinning_maximum_duration), function()
    spinning_timer:stop()
    enemy:start_charging()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(8)
  enemy:set_size(48, 48)
  enemy:set_origin(24, 45)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions("ignored", {
    sword = on_attack_received,
    thrust = on_attack_received
  })

  -- States.
  enemy:set_obstacle_behavior("flying") -- Able to walk over water and lava.
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:start_charging(0)
end)
