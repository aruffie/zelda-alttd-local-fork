----------------------------------
--
-- Shrouded Stalfos Sword.
--
-- Moves randomly over horizontal and vertical axis, and charge the hero if close enough.
--
-- Methods : enemy:start_walking([direction])
--           enemy:start_charging()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
require("enemies/lib/weapons").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local is_charging = false

-- Configuration variables
local charge_triggering_distance = 80
local charging_speed = 64
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_minimum_distance = 16
local walking_maximum_distance = 96
local waiting_duration = 800

-- Start the enemy random movement.
function enemy:start_walking()

  local direction = math.random(4)
  enemy:start_straight_walking(walking_angles[direction], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()    
    sprite:set_animation("immobilized")

    sol.timer.start(enemy, waiting_duration, function()
      if not is_charging then
        enemy:start_walking()
      end
    end)
  end)
end

-- Start the enemy charge movement.
function enemy:start_charging()

  is_charging = true
  enemy:stop_movement()
  enemy:start_target_walking(hero, charging_speed)
  sprite:set_animation("chase")
end

-- Passive behaviors needing constant checking.
enemy:register_event("on_update", function(enemy)

  if enemy:is_immobilized() then
    return
  end

  -- Start charging if the hero is near enough
  if not is_charging and enemy:is_near(hero, charge_triggering_distance) then
    enemy:start_charging()
  end
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:hold_weapon("enemies/shrouded_stalfos_sword/sword")
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_hero_weapons_reactions({
  	arrow = 2,
  	boomerang = 2,
  	explosion = 2,
  	sword = 1,
  	thrown_item = 2,
  	fire = 2,
  	jump_on = "ignored",
  	hammer = 2,
  	hookshot = 2,
  	magic_powder = 2,
  	shield = "protected",
  	thrust = 2
  })

  -- States.
  is_charging = false
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  if is_charging then
    enemy:start_charging()
  else
    enemy:start_walking()
  end
end)