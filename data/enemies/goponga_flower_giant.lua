-- Lua script of enemy goponga flower giant.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
local audio_manager = require("scripts/audio_manager")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local is_hero_pushable = true

-- Configuration variables.
local waiting_minimum_time = 2000
local waiting_maximum_time = 4000

-- Make hero retreat on sword attack received
function on_sword_attack_received()

  if is_hero_pushable then
    is_hero_pushable = false
    enemy:start_pushing_back(hero, 200, 100)
    sprite:set_animation("bounce", function()
      sprite:set_animation("walking")
    end)
    sol.timer.start(enemy, 300, function() -- Only push once even if the sword still collide at following frames.
      is_hero_pushable = true
    end)
  end
end

-- Make enemy wait for attacking.
function enemy:wait()

  sol.timer.start(enemy, math.random(waiting_minimum_time, waiting_maximum_time), function()
    local x, y, layer = enemy:get_position()
    map:create_enemy({
      breed = "projectiles/fireball",
      x = x,
      y = y,
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
    boomerang = 1,
    fire = 1,
    sword = on_sword_attack_received
  })

  -- States.
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:wait()
end)
