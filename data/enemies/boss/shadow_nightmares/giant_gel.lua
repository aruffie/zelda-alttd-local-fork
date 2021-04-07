----------------------------------
--
-- Giant Gel's Shadow.
--
-- Gel enemy that jumps to the hero and is only vulnerable to magic powder.
-- Disappear after hurt and reappear at the initial position if not hurt again during the shaking duration.
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
local map_tools = require("scripts/maps/map_tools")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local circle = math.pi * 2.0
local initial_position
local is_hurt = false

-- Configuration variables
local waiting_minimum_duration = 500
local waiting_maximum_duration = 1000
local jumping_speed = 120
local jumping_height = 16
local jumping_duration = 500
local hurt_duration = 200
local shaking_duration = 1300
local respawning_probability = 0.2
local disappeared_duration = 1000
local dying_duration = 2000

-- Make the enemy disappear then respawn at the initial position.
local function start_disappearing()

 enemy:set_hero_weapons_reactions({magic_powder = "protected"})
 sprite:set_animation("disappearing", function()
    enemy:set_position(initial_position.x, initial_position.y)
    sprite:set_xy(0, 0)
    sol.timer.start(enemy, disappeared_duration, function()
      sprite:set_animation("appearing", function()
        enemy:restart()
      end)
    end)
  end)
end

-- Start a jump to the hero.
local function start_jumping()

  sprite:set_animation("taking_off", function()
    sprite:set_animation("jumping")
    enemy:start_jumping(jumping_duration, jumping_height, enemy:get_angle(hero), jumping_speed, function()
      sprite:set_animation("landing", function()
        if math.random() < respawning_probability then
          start_disappearing()
          return
        end
        sprite:set_animation("stopped")
        sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
          enemy:restart()
        end)
      end)
    end)
  end)
end

-- Check if the custom death as to be started before triggering the built-in hurt behavior.
local function hurt()

  if is_hurt then
    return
  end
  is_hurt = true
  sol.timer.stop_all(enemy)
  enemy:stop_movement()
  enemy:set_hero_weapons_reactions({magic_powder = "protected"})

  -- Die without animation if no more life.
  if enemy:get_life() - 1 < 1 then

    -- Wait a few time, start 2 sets of explosions close from the enemy, wait a few time again and finally make the final explosion and enemy die.
    enemy:start_death(function()
      sprite:set_animation("hurt")
      sol.timer.start(enemy, hurt_duration, function()
        sprite:set_animation("shaking")
        sol.timer.start(enemy, dying_duration, function()
          finish_death()
        end)
      end)
    end)
    return
  end

  -- Make the enemy manually hurt, then shake, the disappear and reappear at its initial position.
  enemy:set_life(enemy:get_life() - 1)
  sprite:set_animation("hurt")
  sol.timer.start(enemy, hurt_duration, function()
    is_hurt = false
    enemy:set_hero_weapons_reactions({magic_powder = hurt})
    sprite:set_animation("shaking")
    sol.timer.start(enemy, shaking_duration, function()
      if math.random() < respawning_probability then
        start_disappearing()
        return
      end
      enemy:restart()
    end)
  end)

  if enemy.on_hurt then
    enemy:on_hurt()
  end
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(3)
  enemy:set_size(48, 32)
  enemy:set_origin(24, 29)

  local x, y = enemy:get_position()
  initial_position = {x = x, y = y}
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions({
  	arrow = "protected",
  	boomerang = "protected",
  	explosion = "ignored",
  	sword = "protected",
  	thrown_item = "protected",
  	fire = "protected",
  	jump_on = "ignored",
  	hammer = "protected",
  	hookshot = "protected",
  	magic_powder = hurt,
  	shield = "protected",
  	thrust = "protected",
  })

  -- States.
  sprite:set_xy(0, 0)
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  enemy:set_layer_independent_collisions(true)
  start_jumping()
end)
