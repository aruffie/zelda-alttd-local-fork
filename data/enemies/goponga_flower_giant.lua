----------------------------------
--
-- Goponga Flower Giant.
--
-- Immobile enemy that repulse on sword attack received, and regularly throw projectile to the hero.
--
-- Methods : enemy:wait()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
local audio_manager = require("scripts/audio_manager")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5

-- Configuration variables.
local waiting_minimum_time = 4000
local waiting_maximum_time = 5000

-- Make enemy wait for attacking.
function enemy:wait()

  sol.timer.start(enemy, math.random(waiting_minimum_time, waiting_maximum_time), function()

    if not camera:overlaps(enemy:get_max_bounding_box()) then
      return true
    end

    local x, y, layer = enemy:get_position()
    map:create_enemy({
      name = (enemy:get_name() or enemy:get_breed()) .. "_flowerball",
      breed = "projectiles/flowerball",
      x = x,
      y = y - 13,
      layer = layer,
      direction = enemy:get_direction4_to(hero)
    })

    sprite:set_animation("attacking", function()
      sprite:set_animation("closing", function()
        sprite:set_animation("walking")
      end)
    end)
    enemy:wait()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(32, 32)
  enemy:set_origin(16, 29)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_hero_weapons_reactions({
  	arrow = "protected",
  	boomerang = 2,
  	explosion = "ignored",
  	sword = "protected",
  	thrown_item = "protected",
  	fire = 2,
  	jump_on = "ignored",
  	hammer = "protected",
  	hookshot = 1,
  	magic_powder = "ignored",
  	shield = "protected",
  	thrust = "protected"
  })

  -- States.
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_push_hero_on_sword(true)
  enemy:set_attacking_collision_mode("touching")
  enemy:set_traversable(false)
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:wait()
end)
