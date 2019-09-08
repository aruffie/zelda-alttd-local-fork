-- Lua script of enemy vire.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local attack_count = 0

-- Configuration variables
local take_off_duration = 1000
local flying_height = 32
local flying_speed = 24
local charging_speed = 175
local attack_triggering_distance = 35
local between_attacks_delay = 2000

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
function enemy:throw_plasmaballs()

  enemy:create_projectile("plasmaball")
  local plasmaball = enemy:create_projectile("plasmaball")
  local plasmaball_movement = plasmaball:get_movement()
  plasmaball_movement:set_angle(plasmaball_movement:get_angle() + 0.1)
end

-- Start charging to the hero
function enemy:start_charging(offensive)

  local hero_x, hero_y, _ = hero:get_position()
  local enemy_x, enemy_y, _ = enemy:get_position()
  local angle = math.atan2(hero_y - enemy_y, enemy_x - hero_x) + (offensive and math.pi or 0)
  enemy:start_straight_walking(angle, charging_speed)
  enemy:get_movement():set_ignore_obstacles(true)
end

-- Start the right attack depending on the hero distance and last attack.
function enemy:start_attacking()

  if not enemy:is_near(hero, attack_triggering_distance) then

    -- Throw two plasmballs two times if far enough, then charge.
    sol.timer.start(enemy, between_attacks_delay, function()
      attack_count = attack_count + 1
      if attack_count < 3 then
        enemy:throw_plasmaballs()
      else
        enemy:start_charging(true)
        return false
      end
      return true
    end)
  else

    -- Run away if the hero is too close.
     enemy:start_charging(false)
  end
end

-- Start enemy movement.
function enemy:start_taking_off()

  enemy:start_flying(take_off_duration, flying_height, false, false)
  enemy:start_straight_walking(math.random(4) * quarter, flying_speed)

  local movement = enemy:get_movement()
  movement:set_ignore_obstacles(true)
  function movement:on_position_changed()
    movement:set_angle(movement:get_angle() - 0.02)
  end
end

-- Start attacking once took off.
enemy:register_event("on_flying_took_off", function(enemy)
  enemy:start_attacking()
end)

-- Replace on sprite position when dying.
enemy:register_event("on_dying", function(enemy)
  enemy:replace_on_sprite()
end)

-- Create two bats projectiles on dead.
enemy:register_event("on_dead", function(enemy)

  enemy:create_projectile("bat", 0)
  enemy:create_projectile("bat", 2)
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
  enemy:set_hero_weapons_reactions(1, {
    boomerang = 2,
    hammer = 2,
    explosion = 3,
    jump_on = "ignored",
    thrown_item = "ignored",
    hookshot = "immobilized",
    fire = "custom"})

  -- States.
  attack_count = 0
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:replace_on_sprite()
  enemy:start_taking_off()
end)