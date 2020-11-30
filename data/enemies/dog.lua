----------------------------------
--
-- Dog.
--
-- Dog enemy that can moves into 8 directions and jump to the enemy on hurt.
--
----------------------------------

-- Global variables.
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local eighth = math.pi * 0.25
local is_angry = false

-- Configuration variables
local walking_angles = {0, eighth, 2.0 * eighth, 3.0 * eighth, 4.0 * eighth, 5.0 * eighth, 6.0 * eighth, 7.0 * eighth}
local walking_speed = 32
local walking_minimum_distance = 32
local walking_maximum_distance = 64
local waiting_minimum_duration = 1000
local waiting_maximum_duration = 2000
local angry_speed = 80
local jumping_triggering_distance = 40
local jumping_speed = 120
local jumping_duration = 500
local jumping_height = 8
local jumping_end_duration = 1500

-- Make the enemy attacks the hero on hurt.
local function on_attack_received()

  is_angry = true
  enemy:hurt(0)
end

-- Start the enemy walking movement.
local function start_walking()

  enemy:start_straight_walking(walking_angles[math.random(8)], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    sprite:set_animation("waiting")
    sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
      sprite:set_animation("stop_waiting", function()
        enemy:restart()
      end)
    end)
  end)
end

-- Start the enemy angry movement.
local function start_angry()

  local movement = enemy:start_target_walking(hero, angry_speed)
  sprite:set_animation("angry")

  movement:register_event("on_position_changed", function(movement, x, y, layer)
    if enemy:is_near(hero, jumping_triggering_distance) then
      movement:stop()
      sprite:set_animation("jumping")
      enemy:start_jumping(jumping_duration, jumping_height, enemy:get_angle(hero), jumping_speed, function()
        sprite:set_animation("stop_angry")
        sol.timer.start(enemy, jumping_end_duration, function()
          is_angry = false
          enemy:restart()
        end)
      end)
    end
  end)
end

-- The enemy appears: set its properties.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(4)
  enemy:start_shadow()
end)

-- The enemy appears: set its properties.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_hero_weapons_reactions({
  	arrow = on_attack_received,
  	boomerang = on_attack_received,
  	explosion = on_attack_received,
  	sword = on_attack_received,
  	thrown_item = on_attack_received,
  	fire = on_attack_received,
  	jump_on = "ignored",
  	hammer = on_attack_received,
  	hookshot = "immobilized",
  	magic_powder = "ignored",
  	shield = "ignored",
  	thrust = on_attack_received
  })

  -- States.
  sprite:set_xy(0, 0)
  enemy:set_damage(2)
  enemy:set_can_attack(is_angry)
  if not is_angry then
    start_walking()
  else
    start_angry()
  end
end)
