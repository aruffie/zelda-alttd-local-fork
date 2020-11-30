----------------------------------
--
-- Mad Bomber.
--
-- Start hidden and regularly appear to throw a bomb to the hero.
-- The enemy stay at the same position, override an event from outside this script to move the position when necessary.
--
-- Events : enemy:on_disappeared()
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
local attacking_timer = nil

-- Configuration variables
local waiting_minimum_duration = 2000
local waiting_maximum_duration = 3000
local before_throwing_bomb_delay = 800
local bomb_throw_duration = 600
local bomb_throw_height = 16
local bomb_throw_speed = 88

-- Make the enemy appear.
local function appear()

  enemy:set_visible()
  sprite:set_animation("appearing", function()

    -- Behavior for each items.
    enemy:set_hero_weapons_reactions({
    	arrow = 1,
    	boomerang = "protected",
    	explosion = "ignored",
    	sword = 1,
    	thrown_item = 1,
    	fire = 1,
    	jump_on = "ignored",
    	hammer = "protected",
    	hookshot = 1,
    	magic_powder = "ignored",
    	shield = "protected",
    	thrust = 1
    })
    enemy:set_can_attack(true)
    sprite:set_animation("walking")

    -- Throw a bomb after some time and disappear.
    attacking_timer = sol.timer.start(enemy, before_throwing_bomb_delay, function()
      local bomb = enemy:create_enemy({
        name = (enemy:get_name() or enemy:get_breed()) .. "_bomb",
        breed = "projectiles/bomb"
      })

      if bomb and bomb:exists() then -- If the bomb was not immediatly removed from the on_created() event.
        enemy:start_throwing(bomb, bomb_throw_duration, 0, bomb_throw_height, enemy:get_angle(hero), bomb_throw_speed, function()
          bomb:explode()
        end)
      end

      sprite:set_animation("disappearing", function()
        enemy:restart()
        if enemy.on_disappeared then
          enemy:on_disappeared()
        end
      end)
    end)
  end)
end

-- Wait a few time and appear.
local function wait()

  sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    if not camera:overlaps(enemy:get_max_bounding_box()) then
      return true
    end
    appear()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(4)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- States.
  enemy:set_visible(false)
  enemy:set_can_attack(false)
  enemy:set_damage(2)
  enemy:set_invincible()
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_obstacle_behavior("flying")
  wait()
end)
