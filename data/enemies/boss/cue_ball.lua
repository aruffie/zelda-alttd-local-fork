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
local head_sprite, splash_sprite
local hurt_frame_delay = sprite:get_frame_delay("hurt")
local quarter = math.pi * 0.5
local circle = math.pi * 2.0
local step = 1

-- Configuration variables
local charging_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local charging_speed = 160
local waiting_duration = 500
local spinning_minimum_duration = 500
local spinning_maximum_duration = 1000

-- Get the upper-left grid node coordinates of the enemy position.
local function get_grid_position()

  local position_x, position_y, _ = enemy:get_position()
  return position_x - position_x % 8, position_y - position_y % 8
end

-- Echo some of the reference_sprite events and methods to the given sprite.
local function synchronize_sprite(sprite, reference_sprite)

  reference_sprite:register_event("on_direction_changed", function(reference_sprite)
    sprite:set_direction(reference_sprite:get_direction())
  end)
  reference_sprite:register_event("on_animation_changed", function(reference_sprite, name)
    if sprite:has_animation(name) then
      sprite:set_animation(name)
    end
  end)
end

-- Hurt if the enemy angle to hero is not on the circle the enemy is looking at. 
local function on_attack_received()

  -- Don't hurt if a previous hurt animation is still running.
  if sprite:get_animation() == "hurt" then
    return
  end

  -- Hurt if the hero touches the enemy main sprite and not the head sprite.
  local hero_state, hero_state_object = hero:get_state()
  local is_hero_running = (hero_state == "running" or (hero_state == "custom" and hero_state_object:get_description() == "running"))
  if enemy:overlaps(hero, "sprite", sprite) and not enemy:overlaps(hero, "sprite", head_sprite) then

    -- Stop the current hero run and freeze it for some time if running.
    if is_hero_running then
      hero:freeze()
      sol.timer.start(hero, 300, function()
        hero:unfreeze()
      end)
    end

    -- Manually hurt the enemy to not restart it automatically and start spinning through a randomized direction.
    enemy:set_life(enemy:get_life() - 1)
    enemy:start_spinning()
    step = (math.random(2) == 1) and -1 or 1
  else
    if is_hero_running then
      hero:start_hurt(enemy, enemy:get_damage())
    end
  end
end

-- Start the enemy movement.
function enemy:start_charging(direction4)

  direction4 = direction4 or sprite:get_direction()
  splash_sprite:set_animation("walking")
  enemy:start_straight_walking(charging_angles[direction4 + 1], charging_speed, nil, function()
    sprite:set_animation("stopped")
    splash_sprite:stop_animation()
    sol.timer.start(enemy, waiting_duration, function()
      enemy:start_charging((direction4 - step) % 4)
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
  enemy:set_origin(24, 24)
  enemy:set_position(get_grid_position()) -- Set the position to the center of the current 16*16 case instead of 8, 13.
  enemy:set_drawn_in_y_order(false) -- Display the legs and body part as a flat entity.

  -- Add the head sprite as the protected one.
  head_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/head")
  synchronize_sprite(head_sprite, sprite)

  -- Add shadow and effect.
  enemy:start_shadow("enemies/boss/cue_ball/shadow")
  splash_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/splash_effect")
  enemy:set_invincible_sprite(splash_sprite)
  enemy:bring_sprite_to_back(splash_sprite)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items and sprite.
  enemy:set_hero_weapons_reactions("protected", {
    sword = on_attack_received,
    thrust = on_attack_received,
    jump_on = "ignored"
  })
  enemy:set_thrust_reaction_sprite(head_sprite, "protected")
  enemy:set_attack_consequence_sprite(head_sprite, "sword", "protected")

  -- States.
  enemy:set_obstacle_behavior("flying") -- Able to walk over water and lava.
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:start_charging(0)
end)
