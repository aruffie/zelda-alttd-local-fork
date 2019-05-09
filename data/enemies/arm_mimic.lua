-- Lua script of enemy arm_mimic.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement

-- The enemy appears: set its properties.
function enemy:on_created()

  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(1)
  enemy:set_damage(12)
  enemy:set_attack_consequence("sword", 0)
  enemy:set_attack_consequence("arrow", 0)
  enemy:set_attack_consequence("thrown_item", 0)
  enemy:set_attack_consequence("explosion", 1)
  enemy:set_attack_consequence("boomerang", 'immobilized')
  enemy:set_hammer_reaction(0)

end

-- The enemy was stopped for some reason and should restart.
function enemy:on_restarted()
  
  local sprite = enemy:get_sprite()
  sprite:set_animation("walking")
  sprite:set_paused(true)
  movement = sol.movement.create("target")
  local x_hero, y_hero = hero:get_position()
  sol.timer.start(enemy, 50, function()
    if hero:get_state() ~= "running" then
      enemy:set_attack_consequence("sword", 0)
      local direction = 0
      local movement_hero = hero:get_movement()
      if not movement_hero then
        direction = hero:get_sprite():get_direction()
      else
        direction = movement_hero:get_direction4()
      end
      local direction_enemy = 0
      if direction == 0 then
        direction_enemy = 2
      elseif direction == 1 then
        direction_enemy = 3
      elseif direction == 3 then
        direction_enemy = 1
      end
      local x_new_hero, y_new_hero = hero:get_position()
      local x_enemy, y_enemy = enemy:get_position()
      local diff_x = x_new_hero - x_hero
      local diff_y = y_new_hero - y_hero
      if diff_x ~= 0 or diff_y  ~= 0 then
        sprite:set_paused(false)
      else
        sprite:set_paused(true)
      end
      x_enemy = x_enemy - diff_x
      y_enemy = y_enemy - diff_y
      enemy:get_sprite():set_direction(direction_enemy)
      movement:set_target(x_enemy, y_enemy)
      movement:set_speed(200)
      movement:start(enemy)
      x_hero = x_new_hero
      y_hero  = y_new_hero
    else
      self:set_attack_consequence("sword", 1)
      local x_new_hero, y_new_hero = hero:get_position()
      x_hero = x_new_hero
      y_hero  = y_new_hero
    end
    return true
  end)

end

function enemy:on_custom_attack_received(attack)

  -- Custom reaction: don't get hurt but step back.
  sol.timer.stop_all(enemy)  -- Stop the towards_hero behavior.
  local hero = enemy:get_map():get_hero()
  local angle = hero:get_angle(enemy)
  local movement_straight = sol.movement.create("straight")
  movement_straight:set_speed(64)
  movement_straight:set_angle(angle)
  movement_straight:start(enemy)
  sol.timer.start(enemy, 400, function()
    enemy:restart()
  end)

end