-- Lua script of enemy moblin chief.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local current_hero_offset_x
local first_start = true
local spear_count

-- Configuration variables
local minimum_spear = 3
local maximum_spear = 5
local throwed_spear_offset_x = 0
local throwed_spear_offset_y = -32
local minimum_distance_to_hero = 100
local jumping_speed = 80
local jumping_height = 6
local jumping_duration = 200
local jumping_duration_decrease_by_hp = 5
local waiting_duration = 700
local charging_speed = 160
local charging_maximum_distance = 180
local bounce_speed = 40
local bounce_height = 32
local bounce_duration = 600
local shocked_duration = 2000
local searching_duration = 1600
local action_probability = 0.2

-- Update the target direction depending on hero position.
local function update_direction()

  local x, _, _ = enemy:get_position()
  local hero_x, _, _ = hero:get_position()
  current_hero_offset_x = hero_x < x and minimum_distance_to_hero or -minimum_distance_to_hero
  sprite:set_direction(hero_x < x and 2 or 0)
end

-- Start the enemy jumping movement to the hero.
function enemy:start_moving()

  local hero_x, hero_y, _ = hero:get_position()
  local target_x, target_y = hero_x + current_hero_offset_x, hero_y
  local angle = enemy:get_angle(target_x, target_y)
  local speed = jumping_speed * math.min(1.0, enemy:get_distance(target_x, target_y) / (jumping_speed * 0.2))
  local duration = jumping_duration - jumping_duration_decrease_by_hp * (8 - enemy:get_life())
  local movement = enemy:start_jumping(duration, jumping_height, angle, speed, function()

    -- Check if an action should occurs at the end of the jump, throw or charge depending on spear count.
    if math.random() <= action_probability then
      if spear_count > 0 then
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

-- Start throwing a spear to the hero.
function enemy:start_throwing()

  local direction = current_hero_offset_x > 0 and 2 or 0
  sprite:set_direction(direction)
  sprite:set_animation("aiming", function()
    sprite:set_animation("throwing", function()
      enemy:start_moving()
    end)
    local projectile = enemy:create_enemy({
      breed = "projectiles/spear",
      x = throwed_spear_offset_x,
      y = throwed_spear_offset_y,
      direction = direction
    })
    spear_count = spear_count - 1
  end)
end

-- Start charging to the hero.
function enemy:start_charging()

  local angle = current_hero_offset_x > 0 and math.pi or 0
  sprite:set_animation("prepare_attacking")
  sol.timer.start(enemy, waiting_duration, function()
    local movement = enemy:start_straight_walking(angle, charging_speed, charging_maximum_distance, function()
      -- Restart jumping on movement finished if no obstacle reached.
      enemy:restart()
    end)

    -- Start being shocked and vulnerable if obstacle reached.
    function movement:on_obstacle_reached()
      movement:stop()
      sprite:set_animation("shocked")
      enemy:start_brief_effect("entities/effects/impact_projectile", "default", math.cos(angle) * 24, -20)
      enemy:start_jumping(bounce_duration, bounce_height, angle + math.pi, bounce_speed, function()
        sol.timer.start(enemy, shocked_duration, function()
          enemy:restart()
        end)
      end)

      -- TODO Stop and laugh on hero touched.

      enemy:set_hero_weapons_reactions(1, {jump_on = "ignored"})
    end
    sprite:set_animation("attacking")
  end)
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
  enemy:start_shadow()

  update_direction()
end)

-- Set the first move direction on enabled.
enemy:register_event("on_enabled", function(enemy)
  first_start = true
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  spear_count = math.random(minimum_spear, maximum_spear)
  sprite:set_xy(0, 0)
  enemy:set_invincible()
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  if first_start then
    first_start = false
    sprite:set_animation("waiting")
    sol.timer.start(enemy, 100, function() -- Wait a very few time before throwing the first spear.
      enemy:start_throwing()
    end)
  else
    enemy:start_searching()
  end
end)
