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
local ball

-- Configuration variables
local jumping_speed = 80
local jumping_height = 6
local jumping_duration = 200

-- Update the target direction depending on hero or ball position.
local function update_direction()

  local x, _, _ = enemy:get_position()
  local hero_x, _, _ = hero:get_position()
  sprite:set_direction(hero_x < x and 2 or 0)
end

-- Check if the custom death as to be started before triggering the built-in hurt behavior.
local function hurt(damage)

  -- Custom die if no more life.
  if enemy:get_life() - damage < 1 then

    -- Wait a few time, start 2 sets of explosions close from the enemy, wait a few time again and finally make the final explosion and enemy die.
    enemy:start_death(function()
      sprite:set_animation("hurt")
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

-- Start the enemy hopping movement.
function enemy:start_hopping()

  local hero_x, hero_y, _ = hero:get_position()
  local target_x, target_y = hero_x + current_hero_offset_x, hero_y + offset_distance_y_to_hero
  local angle = enemy:get_angle(target_x, target_y)
  local speed = jumping_speed * math.min(1.0, enemy:get_distance(target_x, target_y) / (jumping_speed * 0.2))
  local duration = jumping_duration - jumping_duration_decrease_by_hp * (8 - enemy:get_life())
  local movement = enemy:start_jumping(duration, jumping_height, angle, speed, function()

    -- Check if an action should occurs at the end of the jump, throw or charge depending on sai count.
    if math.random() <= action_probability then
      if sai_count > 0 then
        enemy:start_throwing()
      else
        enemy:start_charging()
      end
    else
      enemy:start_moving()
    end
  end)
  movement:set_smooth(true)
  sprite:set_animation("walking")
end

-- Start throwing the ball to the hero.
function enemy:start_throwing()

end

-- Make the enemy search for the hero then start moving.
function enemy:start_searching()

  sprite:set_animation("searching")
  sol.timer.start(enemy, searching_duration, function()
    update_direction()
    enemy:start_moving()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(8)
  enemy:set_size(48, 48)
  enemy:set_origin(24, 45)
  enemy:set_hurt_style("boss")
  enemy:start_shadow()

  ball = map:create_custom_entity({
    direction = 0,
    x = 0,
    y = 0,
    layer = enemy:get_layer(),
    width = 16,
    height = 16,
    sprite = sprite_name or "entities/iron_ball"
  })

  update_direction()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  sprite:set_xy(0, 0)
  enemy:set_invincible()
  enemy:set_can_attack(true)
  enemy:set_damage(4)
end)
