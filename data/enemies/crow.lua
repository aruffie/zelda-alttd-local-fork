-- Lua script of enemy crow.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local circle = math.pi * 2.0
local is_attacking = false
local turning_time = 0

-- Configuration variables
local after_awake_delay = 1000
local take_off_duration = 1000
local targeting_hero_duration = 1000
local turning_duration = 500
local flying_speed = 88
local flying_height = 24
local triggering_distance = 60

-- Set the sprite direction 0 or 2 depending on the given angle.
local function set_sprite_direction2(angle)

  angle = angle % circle
  sprite:set_direction(angle > quarter and angle < 3.0 * quarter and 2 or 0)
end

-- Set given angle to movement and correct direction to the enemy sprite.
local function set_hero_target_angle(movement)

  local angle = enemy:get_angle_from_sprite(sprite, hero)
  movement:set_angle(angle)
  set_sprite_direction2(angle)
end

-- Start flying to the hero then slightly turn after a delay.
function enemy:start_attacking()

  is_attacking = true
  local turning_angle = (math.random(2) - 1.5) * 0.04 

  -- Start a target walking from enemy sprite to hero.
  local movement = enemy:start_straight_walking(0, flying_speed)
  movement:set_ignore_obstacles(true)
  set_hero_target_angle(movement)
  function movement:on_position_changed()
    set_hero_target_angle(movement)
  end

  -- Replace the on_position() event with the new movement after some time.
  sol.timer.start(enemy, targeting_hero_duration, function()
    function movement:on_position_changed()
      local angle = movement:get_angle()
      if turning_time < turning_duration then
        angle = angle + turning_angle
        turning_time = turning_time + 10
        movement:set_angle(angle)
      end
      set_sprite_direction2(angle)
    end
  end)
end

-- Wait for the hero to be close enough and start flying if yes.
function enemy:wait()

  sol.timer.start(enemy, 100, function()
    if enemy:get_distance(hero) < triggering_distance then

      local x, _, _ = enemy:get_position()
      local hero_x, _, _ = hero:get_position()

      sprite:set_direction(hero_x < x and 2 or 0)
      sprite:set_animation("flying")
      enemy:start_flying(take_off_duration, flying_height, function()
        sol.timer.start(enemy, after_awake_delay, function()
          enemy:start_attacking()
        end)
      end)

      return false
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
  enemy:set_hero_weapons_reactions(1, {
    boomerang = 2,
    hookshot = 2,
    charge = 2,
    jump_on = "ignored"
  })

  -- States.
  sprite:set_animation("waiting")
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:set_layer_independent_collisions(true)
  if not is_attacking then
    enemy:wait()
  else
    enemy:start_attacking()
  end
end)
