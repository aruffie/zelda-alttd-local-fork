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
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5

-- Configuration variables.
local waiting_minimum_time = 4000
local waiting_maximum_time = 5000

-- Make hero pushed back on sword attack received.
local function on_sword_attack_received()

  -- Make sure to only trigger this event once by attack.
  enemy:set_invincible()

  enemy:start_pushing_back(hero, 200, 100)
  sprite:set_animation("bounce", function()
    enemy:restart()
  end)
end

-- Make enemy wait for attacking.
function enemy:wait()

  sol.timer.start(enemy, math.random(waiting_minimum_time, waiting_maximum_time), function()

    if not enemy:is_watched(sprite) then
      return true
    end

    local x, y, layer = enemy:get_position()
    local flowerball = map:create_enemy({
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

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions("ignored", {
    hookshot = 1,
    boomerang = 2,
    fire = 2,
    sword = on_sword_attack_received
  })

  -- States.
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_attacking_collision_mode("touching")
  enemy:set_traversable(false)
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:wait()
end)
