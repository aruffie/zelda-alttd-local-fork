----------------------------------
--
-- Armos.
--
-- Immobile at start and wait to be touched by the hero to wake up, then target him.
--
-- Methods : enemy:start_walking()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local eighth = math.pi * 0.25
local is_awake = false

-- Configuration variables
local walking_angles = {0, eighth, 2.0 * eighth, 3.0 * eighth, 4.0 * eighth, 5.0 * eighth, 6.0 * eighth, 7.0 * eighth}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96
local shaking_duration = 1000
local before_moving_delay = 1000

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(8)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    enemy:start_walking()
  end)
end

-- Passive behaviors needing constant checking.
enemy:register_event("on_update", function(enemy)

  if enemy:is_immobilized() then
    return
  end

  -- Awake on touching.
  if not is_awake and enemy:overlaps(hero, "touching") then
    is_awake = true
    sprite:set_animation("shaking")
    sol.timer.start(enemy, shaking_duration, function()
      sprite:set_animation("immobilized")
      sol.timer.start(enemy, before_moving_delay, function()
        enemy:set_traversable(true)
        enemy:set_can_attack(true)
        enemy:set_hero_weapons_reactions({
        	arrow = 2,
        	boomerang = 1,
        	explosion = 2,
        	sword = "protected",
        	hammer = "protected",
        	hookshot = "immobilized",
        	shield = "protected",
        })
        enemy:start_walking()
      end)
    end)
  end
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_hero_weapons_reactions({
  	arrow = "protected",
  	boomerang = "protected",
  	explosion = "ignored",
  	sword = "ignored",
  	thrown_item = "protected",
  	fire = "protected",
  	jump_on = "ignored",
  	hammer = "ignored",
  	hookshot = "protected",
  	magic_powder = "ignored",
  	shield = "ignored",
  	thrust = "protected"
  })

  -- States.
  is_awake = false
  sprite:set_animation("sleep")
  enemy:set_traversable(false)
  enemy:set_can_attack(false)
  enemy:set_damage(8)
end)
