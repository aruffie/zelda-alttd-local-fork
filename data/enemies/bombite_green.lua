----------------------------------
--
-- Bombite Green.
--
-- Moves randomly over horizontal and vertical axis.
-- Run to the hero and start a countdown before exploding when attacked.
--
-- Methods : enemy:start_countdown(number)
--           enemy:start_walking()
--           enemy:start_running()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local is_pushed_back = false
local is_counting_down = false
local countdown_step = nil

-- Configuration variables
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 32
local walking_distance = 16
local running_speed = 80
local waiting_duration = 500
local number_duration = 1000

-- Behavior on effective shot received.
local function on_regular_attack_received()

  -- Make sure to only trigger this event once by attack.
  if is_pushed_back then
    return
  end
  is_pushed_back = true

  -- Repulse the enemy, then follow the hero and start counting down if not already doing it.
  enemy:start_pushed_back(hero, 200, 150, sprite, nil, function() -- Don't use enemy:hurt(0) to not force the hurt animation but still repulse the enemy.
    is_pushed_back = false
    if not is_counting_down then
      enemy:stop_movement()
      enemy:start_countdown(3)
      enemy:set_damage(0)
      enemy:set_can_attack(false)
    end
    enemy:start_running()
  end)
end

-- Make the enemy start counting down.
function enemy:start_countdown(number)

  is_counting_down = true

  sol.timer.start(enemy, number_duration, function()
    if number == 0 then
      local x, y, layer = enemy:get_position()
      map:create_custom_entity({
        model = "explosion",
        direction = 0,
        x = x,
        y = y,
        layer = layer,
        width = 16,
        height = 16,
        properties = {
          {key = "damage_on_hero", value = enemy:get_damage()},
          {key = "hurtable_type_1", value = "hero"},
          {key = "hurtable_type_2", value = "enemy"}
        }
      })
      enemy:start_death()
      return
    end
    countdown_step = number
    sprite:set_animation(number)
    enemy:start_countdown(number - 1)
  end)
end

-- Start the enemy walking movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, walking_distance, function()
    sol.timer.start(enemy, waiting_duration, function()
      if not is_pushed_back and not is_counting_down then
        enemy:start_walking()
      end
    end)
  end)
end

-- Start the enemy running movement.
function enemy:start_running()

  local movement = enemy:start_target_walking(hero, running_speed)
  function movement:on_position_changed(x, y, layer)
    if enemy:overlaps(hero) then

      -- Freeze the movement while overlapping.
      movement:set_speed(0)
      sol.timer.start(enemy, 50, function()
        if not enemy:overlaps(hero) then
          movement:set_speed(running_speed)
          return false
        end
        return true
      end)
    end
  end
  sprite:set_animation(countdown_step or "smiling")
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_hero_weapons_reactions({
  	arrow = "protected",
  	boomerang = "immobilized",
  	explosion = on_regular_attack_received,
  	sword = on_regular_attack_received,
  	thrown_item = "protected",
  	fire = "protected",
  	jump_on = "ignored",
  	hammer = "protected",
  	hookshot = "immobilized",
  	magic_powder = "ignored",
  	shield = "protected",
  	thrust = on_regular_attack_received
  })

  -- States.
  countdown_step = nil
  is_counting_down = false
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:start_walking()
end)
