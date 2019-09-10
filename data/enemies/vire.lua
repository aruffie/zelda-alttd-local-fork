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
local attack_count = 0
local is_charging = false

-- Configuration variables
local take_off_duration = 1000
local flying_height = 32
local flying_speed = 24
local charging_speed = 175
local runaway_triggering_distance = 30
local before_attacks_delay = 3000
local between_attacks_delay = 2000
local before_respawn_delay = 1000
local disappear_distance = 64

local function get_random_position_on_border(entity)

  local x, y = camera:get_position()
  local width, height = entity:get_size()
  local mid_point = width + height
  local random_point = math.random(mid_point * 2)

  return x + (random_point > mid_point + width and 0 or math.max(width, random_point % mid_point)), 
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
    local x, y, _ = enemy:get_position()
    if not camera:overlaps(x - disappear_distance, y - disappear_distance, disappear_distance * 2, disappear_distance * 2) then
      movement:stop()
      sol.timer.start(enemy, before_respawn_delay, function()
        enemy:replace_on_sprite()
        enemy:set_position(get_random_position_on_border(camera))
        enemy:start_taking_off()
      end)
    end
  end
end

-- Throw two magma balls two times if far enough, then charge.
function enemy:start_attacking()
  
  sol.timer.start(enemy, before_attacks_delay, function()
    sol.timer.start(enemy, between_attacks_delay, function()
      attack_count = attack_count + 1
      if attack_count < 3 then
        enemy:throw_magma_balls()
        return true
      end
      enemy:start_charging(true)
    end)
  end)
end

-- Start enemy flying behavior.
function enemy:start_flying_behavior(angle)

  is_charging = false
  attack_count = 0
  enemy:start_straight_walking(angle or enemy:get_angle(hero), flying_speed)
  enemy:start_attacking()
  local movement = enemy:get_movement()
  movement:set_ignore_obstacles(true)

  -- TODO Replace and change the angle if the enemy has a part out screen.
  --[[ function movement:on_position_changed()
    local x, y, _ = enemy:get_position()
    local x_offset, y_offset = sprite:get_xy()
    if not camera:overlaps(x + x_offset, y + y_offset) then
      movement:set_angle(movement:get_direction4() * quarter - quarter)
    end
  end --]]
end

-- Start enemy movement.
function enemy:start_taking_off(direction)

  enemy:replace_on_sprite()
  enemy:start_flying_behavior(direction)
  enemy:start_flying(take_off_duration, flying_height, false, false)
end

-- Replace on sprite position when dying.
enemy:register_event("on_dying", function(enemy)
  enemy:replace_on_sprite()
end)

-- Create two bats projectiles on dead.
enemy:register_event("on_dead", function(enemy)

  enemy:create_projectile("bat", 0)
  enemy:create_projectile("bat", 2)
end)

-- Passive behaviors needing constant checking.
enemy:register_event("on_update", function(enemy)

  if enemy:is_immobilized() then
    return
  end

  -- Run away if the hero is too close.
  if not is_charging and enemy:is_near(hero, runaway_triggering_distance, sprite:get_xy()) then
    enemy:start_charging(false)
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
    boomerang = 3,
    magic_powder = 3,
    fire = 3,
    pegasus_boots = 2,
    hookshot = 2,
    jump_on = "ignored"})

  -- States.
  enemy:set_layer_independent_collisions(true)
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:start_taking_off(0)
end)