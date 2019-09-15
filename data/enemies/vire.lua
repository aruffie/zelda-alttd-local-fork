-- Lua script of enemy vire.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local attacking_timer = nil
local attack_count = 0
local is_charging = false
local is_executed = false

-- Configuration variables
local take_off_duration = 1000
local fall_down_duration = 150
local fall_down_bounce_duration = 300
local fall_down_bounce_height = 8
local flying_height = 32
local flying_speed = 24
local charging_speed = 175
local runaway_triggering_distance = 32
local before_attacks_delay = 3000
local between_attacks_delay = 2000
local before_respawn_delay = 1000

-- Return a random position on the border of the screen.
local function get_random_position_on_screen_border()

  local x, y = camera:get_position()
  local width, height = camera:get_size()
  local mid_point = width + height
  local random_point = math.random(mid_point * 2)

  return x + (random_point > mid_point + width and 0 or math.min(width, random_point % mid_point)), 
         y + math.min(height, math.max(0, random_point - width) % mid_point)
end

-- Replace the enemy position on the sprite and remove the sprite offset.
function enemy:replace_on_sprite()

  local x, y = enemy:get_position()
  local x_offset, y_offset = sprite:get_xy()
  enemy:set_position(x + x_offset, y + y_offset)
  sprite:set_xy(0, 0)
end

-- Create a projectile.
function enemy:create_projectile(projectile, direction)

  local x, y = sprite:get_xy()
  local projectile = enemy:create_enemy({
    breed = "projectiles/" .. projectile,
    x = x,
    y = y
  })
  projectile:go(direction)

  return projectile
end

-- Throw two plasmballs.
function enemy:throw_magma_balls()

  enemy:create_projectile("magmaball")
  local magmaball = enemy:create_projectile("magmaball")
  local magmaball_movement = magmaball:get_movement()
  magmaball_movement:set_angle(magmaball_movement:get_angle() - 0.4)
end

-- Start charging to or away to the hero.
function enemy:start_charging(offensive)

  is_charging = true
  local hero_x, hero_y, _ = hero:get_position()
  local enemy_x, enemy_y, _ = enemy:get_position()
  local x_offset, y_offset = sprite:get_xy()
  local angle = math.atan2(hero_y - enemy_y - y_offset, enemy_x - hero_x - x_offset) + (offensive and math.pi or 0)
  enemy:start_straight_walking(angle, charging_speed)
  local movement = enemy:get_movement()
  movement:set_ignore_obstacles(true)

  -- Start another flying elsewhere if completely out of the screen while charging.
  function movement:on_position_changed()
    if not camera:overlaps(enemy:get_max_bounding_box()) then
      movement:stop()
      enemy:set_visible(false)
      sol.timer.start(enemy, before_respawn_delay, function()
        if is_charging then
          sprite:set_xy(0, 0)
          enemy:set_position(get_random_position_on_screen_border())
          enemy:start_taking_off()
        end
      end)
    end
  end
end

-- Throw two magma balls two times if far enough, then charge.
function enemy:start_attacking()
  
  attack_count = 0
  sol.timer.start(enemy, before_attacks_delay, function()
    attacking_timer = sol.timer.start(enemy, between_attacks_delay, function()
      if not is_charging then
        attack_count = attack_count + 1
        if attack_count < 3 then
          enemy:throw_magma_balls()
          return true
        end
        attacking_timer = nil
        enemy:start_charging(true)
      end
    end)
  end)
end

-- Start enemy flying behavior.
function enemy:start_flying_movement(angle)

  is_charging = false
  local movement

  -- Start a straight movement if angle is given.
  if angle then
    movement = enemy:start_straight_walking(angle, flying_speed)

    -- Clip and change the angle if the enemy has a part out screen.
    movement:register_event("on_position_changed", function(movement)
      if not is_charging and not enemy:is_sprite_contained(sprite, camera:get_bounding_box()) then
        enemy:clip_sprite_into(sprite, camera:get_bounding_box())
        enemy:start_flying_movement(movement:get_direction4() * quarter - quarter)
        return false
      end
    end)
  else

    -- Start a target walking to the hero else.
    movement = enemy:start_target_walking(hero, flying_speed)
  end
  movement:set_ignore_obstacles(true)

  -- Run away if the hero is too close.
  movement:register_event("on_position_changed", function(movement)
    if enemy:is_near(hero, runaway_triggering_distance, sprite) then
      enemy:start_charging(false)
    end
  end)
end

-- Start enemy movement.
function enemy:start_taking_off(angle)

  if attacking_timer then
    attacking_timer:stop()
  end
  enemy:replace_on_sprite()
  enemy:set_visible()
  enemy:start_flying_movement(angle)
  enemy:start_flying(take_off_duration, flying_height, false, false)
  enemy:start_attacking()
end

-- On hit by boomerang, fire or magic powder, make the enemy fall down and die without splitting into bats.
enemy:register_event("on_custom_attack_received", function(enemy, attack)

  if attack == "boomerang" or attack == "fire" or attack == "magic_powder" then

    is_executed = true
    enemy:stop_flying(fall_down_duration, function()
      enemy:start_jumping(fall_down_bounce_duration, fall_down_bounce_height, nil, nil, function()
        enemy:set_pushed_back_when_hurt(false)
        enemy:hurt(3)
      end)
    end)
  end
end)

-- Replace on sprite position when dying.
enemy:register_event("on_dying", function(enemy)
  enemy:replace_on_sprite()
end)

-- Create two bats projectiles on dead.
enemy:register_event("on_dead", function(enemy)

  if not is_executed then
    enemy:create_projectile("bat", 0)
    enemy:create_projectile("bat", 2)
  end
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(3)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(1, {
    pegasus_boots = 2,
    hookshot = 2,
    boomerang = "custom",
    magic_powder = "custom",
    fire = "custom",
    jump_on = "ignored"})

  -- States.
  enemy:set_layer_independent_collisions(true)
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:start_taking_off(0)
end)