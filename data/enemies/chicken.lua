-- Lua script of enemy chicken.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local map = enemy:get_map()
local angry = false
local num_times_hurt = 0
local sprite
local walking_timer

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- The enemy appears: set its properties.
function enemy:on_created()

  enemy:set_life(10000)
  enemy:set_damage(2)
  enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:set_hurt_style("monster")
  sprite = enemy:get_sprite()
  
end

function enemy:on_movement_changed(movement)

  local direction4 = movement:get_direction4()
  sprite:set_direction(direction4)
  
end

function enemy:on_obstacle_reached(movement)

  if walking_timer then
    walking_timer:stop()
  end
  if not angry then
    enemy:go_random()
  else
    enemy:go_angry()
  end
  
end

-- The enemy was stopped for some reason and should restart.
function enemy:on_restarted()

  if angry then
    enemy:go_angry()
  else
    enemy:go_random()
    sol.timer.start(enemy, 100, function()
      if map.angry_chickens and not angry then
        enemy:go_angry()
        return false
      end
      return true  -- Repeat the timer.
    end)
  end
  
end

function enemy:launch_feeding()
  
  local movement = enemy:get_movement()
  if movement then
    movement:stop()
  end
  sprite:set_animation("feeding")
  sol.timer.start(enemy, 1000, function()
    if not angry then
      enemy:go_random()
    end
  end)
  
end

function enemy:go_random()

  enemy:set_can_attack(false)
  angry = false
  sprite:set_animation("walking")
  local movement = sol.movement.create("random")
  movement:set_speed(32)
  movement:start(enemy)
  sol.timer.start(enemy, 5000, function()
    if not angry then
      enemy:launch_feeding()
    end
  end)
  
end

function enemy:go_angry()

  angry = true
  map.angry_chickens = true
  going_hero = true
  local movement = sol.movement.create("target")
  movement:set_speed(96)
  movement:start(enemy)
  sprite:set_animation("angry")
  enemy:set_can_attack(true)
  
end

function enemy:on_hurt()

  -- Sound
  audio_manager:play_sound("misc/cucco")
  num_times_hurt = num_times_hurt + 1
  if num_times_hurt == 3 and not map.angry_chickens then
    -- Make all chickens of the map attack the hero.
    map.angry_chickens = true
  end
  
end