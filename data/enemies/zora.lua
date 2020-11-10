----------------------------------
--
-- Zora.
--
-- Start hidden and regularly appear from a whirlwind to throw a projectile to the hero.
-- The enemy stay at the same position.
--
-- Methods : enemy:appear()
--           enemy:wait()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
require("enemies/lib/weapons").learn(enemy)
require("scripts/multi_events")
local audio_manager=require("scripts/audio_manager")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local eighth = math.pi * 0.25

-- Configuration variables
local waiting_minimum_duration = 2000
local waiting_maximum_duration = 4000
local appearing_duration = 1000
local throwing_duration = 600
local before_desappearing_delay = 1000

-- Make the enemy appear.
function enemy:appear()

  enemy:set_visible()
  sprite:set_animation("appearing")
  sol.timer.start(enemy, appearing_duration, function()

    enemy:set_hero_weapons_reactions({
    	arrow = 1,
    	boomerang = 1,
    	explosion = 1,
    	sword = 1,
    	thrown_item = 1,
    	fire = 1,
    	jump_on = "ignored",
    	hammer = 1,
    	hookshot = 1,
    	magic_powder = 1,
    	shield = "protected",
    	thrust = 1
    })
    enemy:set_can_attack(true)

    sprite:set_animation("immobilized")

    sol.timer.start(enemy, throwing_duration, function()
      enemy:create_enemy({
        name = (enemy:get_name() or enemy:get_breed()) .. "_fireball",
        breed = "projectiles/fireball"
      })
      sprite:set_animation("firing")
      audio_manager:play_entity_sound(enemy, "enemies/fireball")
      sol.timer.start(enemy, before_desappearing_delay, function()
        sprite:set_animation("disappearing", function()
          enemy:restart()
        end)
      end)
    end)
  end)
end

-- Wait a few time and appear.
function enemy:wait()

  sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    if not camera:overlaps(enemy:get_max_bounding_box()) then
      return true
    end
    enemy:appear()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 24)
  enemy:set_origin(8, 21)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_invincible()

  -- States.
  enemy:set_visible(false)
  enemy:set_can_attack(false)
  enemy:set_damage(2)
  enemy:set_pushed_back_when_hurt(false)
  enemy:wait()
end)

