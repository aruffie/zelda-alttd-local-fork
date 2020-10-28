----------------------------------
--
-- Smasher.
--
-- Hop to be horizontally aligned with the hero and randomly throw three to five sai, then start charging.
-- Hit the wall and be vulnerable if the charge started too close of a wall, else start a search animation and restart.
-- Slightly increase the speed each time the enemy is hurt.
--
--
-- Methods : enemy:start_moving()
--           enemy:start_throwing()
--           enemy:start_charging()
--           enemy:start_searching()
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
local is_ball_carried_by_hero = false
local ball

-- Configuration variables
local ball_initial_offset_x = 80
local ball_initial_offset_y = 48
local jumping_speed = 80
local jumping_height = 6
local jumping_duration = 200

-- Update the target direction depending on hero or ball position.
local function update_direction()

  local x, _, _ = enemy:get_position()
  local hero_x, _, _ = hero:get_position()
  sprite:set_direction(hero_x < x and 2 or 0)
end

-- Create the ball and related events.
local function create_ball()

  local x, y, layer = enemy:get_position()
  ball = map:create_custom_entity({
    direction = 0,
    x = x + ball_initial_offset_x,
    y = y + ball_initial_offset_y,
    layer = layer,
    width = 16,
    height = 16,
    model = "ball",
    sprite = "entities/iron_ball"
  })
  ball:register_event("on_interaction", function(ball)
    is_ball_carried_by_hero = true
  end)
  ball:register_event("on_finish_throw", function(ball)
    is_ball_carried_by_hero = false
  end)
end

-- Check if the custom death as to be started before triggering the built-in hurt behavior.
local function hurt(damage)

  -- Custom die if no more life.
  if enemy:get_life() - damage < 1 then

    -- Wait a few time, start 2 sets of explosions close from the enemy, wait a few time again and finally make the final explosion and enemy die.
    enemy:start_death(function()
      sprite:set_animation("hurt")
      ball:remove() -- Avoid the ball to be carried again.
      sol.timer.start(enemy, 1500, function()
        enemy:start_close_explosions(32, 2500, "entities/explosion_boss", 0, -30, function()
          sol.timer.start(enemy, 1000, function()
            enemy:start_brief_effect("entities/explosion_boss", nil, 0, -30)
            finish_death()
          end)
        end)
        sol.timer.start(enemy, 200, function()
          enemy:start_close_explosions(32, 2300, "entities/explosion_boss", 0, -30)
        end)
      end)
    end)
    return
  end

  -- Else hurt normally.
  enemy:hurt(damage)
end

-- Start the enemy jumping movement.
local function start_jumping()

  --local movement = enemy:start_jumping(duration, jumping_height, angle, speed, function()

  --end)
end

-- Start throwing the ball to the hero.
function enemy:start_throwing()

end

-- Remove the ball on dead.
enemy:register_event("on_dead", function(enemy)
  ball:remove()
end)

-- Enable the ball on enabled.
enemy:register_event("on_enabled", function(enemy)
  ball:set_enabled()
end)

-- Disable the ball on disabled.
enemy:register_event("on_disabled", function(enemy)
  ball:set_enabled(false)
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(4)
  enemy:set_size(48, 48)
  enemy:set_origin(24, 45)
  enemy:start_shadow("enemies/boss/armos_knight/shadow") -- TODO Create a specific shadow.

  create_ball()
  update_direction()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  sprite:set_xy(0, 0)
  enemy:set_hero_weapons_reactions("protected", {thrown_item = function() hurt(1) end})
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:set_pushed_back_when_hurt(false)
  start_jumping()
end)
