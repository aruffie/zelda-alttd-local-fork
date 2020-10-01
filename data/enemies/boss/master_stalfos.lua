-- Lua script of enemy orb monster blue.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local is_on_ground = false

-- Configuration variables
local falling_duration = 1000
local seeking_duration = 750
local waiting_duration = 1000
local aiming_duration = 750
local striking_duration = 1000
local walking_speed = 32
local walking_maximum_duration = 1000
local jumping_maximum_speed = 150
local jumping_height = 32
local jumping_duration = 800
local walking_triggering_distance = 60
local strike_triggering_distance = 40

-- Update the direction2 depending on hero position.
local function update_direction()

  local x, _, _ = enemy:get_position()
  local hero_x, _, _ = hero:get_position()
  sprite:set_direction(hero_x < x and 2 or 0)
end

-- Make the boss fall from the ceiling.
local function start_falling()

  local _, enemy_y = enemy:get_position()
  local _, camera_y = map:get_camera():get_position()
  enemy:set_visible()
  sprite:set_animation("jumping")
  sprite:set_direction(0)

  -- Fall from ceiling.
  enemy:start_throwing(enemy, falling_duration, enemy_y - camera_y, nil, nil, nil, function()
    is_on_ground = true
    sprite:set_animation("waiting")

    -- Start the dialog if any, else look left and right.
    local dialog = enemy:get_property("dialog")
    if dialog then
      game:start_dialog(dialog)
      enemy:restart()
    else
      sol.timer.start(enemy, seeking_duration, function()
        sprite:set_direction(2)
        sol.timer.start(enemy, seeking_duration, function()
          sprite:set_direction(0)
          sol.timer.start(enemy, seeking_duration, function()
            enemy:restart()
          end)
        end)
      end)
    end
  end)
end

-- Make the enemy strike with his sword.
local function start_striking()

  -- Aim for some time, then strike. 
  update_direction()
  sprite:set_animation("aiming")
  sol.timer.start(enemy, aiming_duration, function()
    sprite:set_animation("striking")
    sol.timer.start(enemy, striking_duration, function()
      enemy:restart()
    end)
  end)
end

-- Make the enemy walk to the hero, then strike.
local function start_walking()

  local movement = enemy:start_target_walking(hero, walking_speed)
  sprite:set_animation("walking")

  -- Start the timer of the maximum walk time, and strike once finished.
  local timer = sol.timer.start(enemy, walking_maximum_duration, function()
    movement:stop()
    start_striking()
  end)

  -- If the distance is low enough, start striking.
  function movement:on_position_changed()
    update_direction()

    local distance = enemy:get_distance(hero)
    if distance < strike_triggering_distance then
      timer:stop()
      movement:stop()
      start_striking()
    end
  end
end

-- Start jumping to the hero.
local function start_jumping()

  local distance = enemy:get_distance(hero)
  local angle = enemy:get_angle(hero)
  sprite:set_animation("jumping")
  enemy:start_jumping(jumping_duration, jumping_height, angle, math.min(distance / jumping_duration * 1000, jumping_maximum_speed), function()
    enemy:restart()
  end)
end

-- Decide if the enemy should walk and strike or jump, depending on the distance to the hero.
local function start_waiting()

  sprite:set_animation("waiting")
  update_direction()
  sol.timer.start(enemy, waiting_duration, function()
    if enemy:get_distance(hero) < walking_triggering_distance then
      start_walking()
    else
      start_jumping()
    end
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_visible(false)
  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow("enemies/boss/master_stalfos/shadow")
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(2, {
    sword = 1
  })

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  if is_on_ground then
    start_waiting()
  else
    start_falling()
  end
end)
