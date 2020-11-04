----------------------------------
--
-- Octorok Flying.
--
-- Moves randomly over horizontal and vertical axis.
-- Throw a stone at the end of each walk step if the hero is on the direction the enemy is looking at.
-- Jump over the hero if he attacks too closely.
--
-- Methods : enemy:start_walking()
--           enemy:start_pouncing()
--
----------------------------------


local enemy = ...
require("scripts/multi_events")
require("enemies/lib/weapons").learn(enemy)
local audio_manager=require("scripts/audio_manager")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local is_jumping = false

-- Configuration variables.
local walking_angles = {0, quarter, 2.0 * quarter, 3.0 * quarter}
local walking_speed = 48
local walking_minimum_distance = 16
local walking_maximum_distance = 32
local waiting_duration = 800
local throwing_duration = 200
local jumping_triggering_distance = 44
local jumping_duration = 600
local jumping_height = 20
local jumping_speed = 120

local projectile_breed = "stone"
local projectile_offset = {{0, -8}, {0, -8}, {0, -8}, {0, -8}}

-- Start the enemy movement.
function enemy:start_walking()

  local direction = math.random(4)
  enemy:start_straight_walking(walking_angles[direction], walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function() 
    sprite:set_animation("immobilized")
    sol.timer.start(enemy, waiting_duration, function()
      if not is_jumping then

        -- Throw a stone if the hero is on the direction the enemy is looking at.
        if enemy:get_direction4_to(hero) == sprite:get_direction() then
          enemy:throw_projectile(projectile_breed, throwing_duration, projectile_offset[direction][1], projectile_offset[direction][2], function()
            audio_manager:play_entity_sound(enemy, "enemies/octorok_firing")
            enemy:start_walking()
          end)
        else
          enemy:start_walking()
        end
      end
    end)
  end)
end

-- Start pouncing over the hero.
function enemy:start_pouncing()

  if not is_jumping then
    is_jumping = true
    enemy:start_jumping(jumping_duration, jumping_height, enemy:get_angle(hero), jumping_speed, function()
      enemy:restart()
    end)
    enemy:set_invincible()
    enemy:set_can_attack(false)
    sprite:set_animation("jumping")
    sprite:set_direction(enemy:get_movement():get_direction4())
  end
end

-- Jump on sword triggering too close
map:register_event("on_command_pressed", function(map, command)

  if not enemy:exists() or not enemy:is_enabled() then
    return
  end

  if command == "attack" and enemy:is_near(hero, jumping_triggering_distance) then
    enemy:start_pouncing()
  end
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(1, {jump_on = "ignored"})

  -- States.
  is_jumping = false
  sprite:set_xy(0, 0)
  enemy:set_obstacle_behavior("normal")
  enemy:set_can_attack(true)
  enemy:set_damage(1)
  enemy:start_walking()
end)