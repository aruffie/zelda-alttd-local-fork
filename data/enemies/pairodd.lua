-- Lua script of enemy pairodd.
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
local waiting_timer, before_disappear_timer

-- Configuration variables
local triggering_distance = 48
local before_disappear_delay = 100
local disappear_duration = 1000

-- Set the sprite direction depending on the hero position.
function enemy:set_direction2()

  local x, _, _ = enemy:get_position()
  local hero_x, _, _ = hero:get_position()
  sprite:set_direction(hero_x - x < 0 and 2 or 0)
end

-- Make the enemy appear at the opposite of the camera.
function enemy:appear()

  local camera_x, camera_y = camera:get_position()
  local camera_width, camera_height = camera:get_size()

  enemy:set_position(enemy:get_central_symmetry_position(camera_x + camera_width / 2.0, camera_y + camera_height / 2.0))
  enemy:set_visible()
  enemy:set_direction2()
  sprite:set_animation("appearing", function()

    -- Throw an iceball and restart.
    enemy:create_enemy({breed = "projectiles/iceball"})
    enemy:restart()
  end)
end

-- Make the enemy disappear.
function enemy:disappear()

  enemy:start_brief_effect("entities/symbols/exclamation", nil, -16, -16, 400)
  
  before_disappear_timer = sol.timer.start(enemy, before_disappear_delay, function()
    before_disappear_timer = nil

    sprite:set_animation("disappearing", function()
      enemy:set_invincible()
      enemy:set_can_attack(false)

      sol.timer.start(enemy, disappear_duration, function()
        enemy:appear()
      end)
    end)
  end)
end

-- Start the enemy movement.
function enemy:wait()

  waiting_timer = sol.timer.start(enemy, 50, function()
    if enemy:is_near(hero, triggering_distance) then
      before_disappear_timer = nil
      enemy:disappear()
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
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(2, {
    sword = 1,
    explosion = 1,
    boomerang = "immobilized",
    jump_on = "ignored"
  })

  -- States.
  if waiting_timer then
    waiting_timer:stop()
    waiting_timer = nil
  end
  if before_disappear_timer then
    before_disappear_timer:stop()
    before_disappear_timer = nil
  end
  enemy:set_direction2()
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  enemy:wait()
end)
