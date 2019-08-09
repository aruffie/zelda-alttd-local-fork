-- Lua script of enemy anti_kirby.
-- This script is executed every time an enemy with this model is created.

-- TODO sounds

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local aspiration_sprite = nil
local eighth = math.pi / 4.0

-- Configuration variables
local suction_damage = 2
local contact_damage = 4

local walking_possible_angle = {eighth, 3.0 * eighth, 5.0 * eighth, 7.0 * eighth}
local attack_triggering_distance = 100

local walking_pause_duration = 1000
local eating_duration = 2000
local elevated_duration = 3000
local before_aspiring_delay = 200
local aspiration_on_hero_step_delay = 50
local finish_aspiration_delay = 400

local walking_speed = 48
local walking_distance = 45
local spit_speed = 220
local spit_distance = 64
local elevation_speed = 8
local elevation_distance = 8

-- Return the visual direction (left or right) depending on the sprite direction.
function enemy:get_direction2()

  if sprite:get_direction() < 2 then
    return 0
  end
  return 1
end

-- Check if an attack should be triggered, continue walking else.
function enemy:on_random_walk_finished()

  local _, _, layer = enemy:get_position()
  local _, _, hero_layer = hero:get_position()
  local near_hero = (layer == hero_layer or enemy:has_layer_independent_collisions()) and enemy:get_distance(hero) < attack_triggering_distance

  -- Start aspirate if the hero is near enough, continue walking else.
  if near_hero then
    enemy:start_aspirate()
  else
    sol.timer.start(enemy, walking_pause_duration, function()
      enemy:start_random_walking(walking_possible_angle, walking_speed, walking_distance, sprite)
    end)
  end
end

-- Reset default states after an enemy attack.
function enemy:reset_default_states()

  enemy.is_aspiring = false
  enemy.is_attacking = false
  enemy:set_can_attack(true)
  enemy:start_random_walking(walking_possible_angle, walking_speed, walking_distance, sprite)
end

-- Make the enemy eat the hero.
function enemy:eat_hero()

  if aspiration_sprite then
    enemy:remove_sprite(aspiration_sprite)
    aspiration_sprite = nil
  end
  sprite:stop_movement()
  sprite:set_xy(0, 0)
  sprite:set_animation("eating_link")
  hero:set_visible(false)
  hero:freeze()

  -- Manually hurt and spit the hero after a delay.
  sol.timer.start(enemy, eating_duration, function()
    
    hero:start_hurt(suction_damage)
    hero:set_position(enemy:get_position())
    hero:set_visible()

    local movement = sol.movement.create("straight")
    movement:set_speed(spit_speed)
    movement:set_max_distance(spit_distance)
    movement:set_angle(enemy:get_direction2() * math.pi)
    movement:start(hero)

    function movement:on_finished()
      hero:unfreeze()
    end

    function movement:on_obstacle_reached()
      hero:unfreeze()
    end

    enemy:reset_default_states()
  end)
end

-- Passive behaviors needing constant checking.
function enemy:on_update()

  -- Make the sprite jump if the enemy is not attacking.
  if not enemy.is_attacking then
    sprite:set_xy(0, -math.abs(math.cos(sol.main.get_elapsed_time() / 75.0) * 4.0))
  end

  -- If the hero touches the center of the enemy while aspiring, eat him.
  if enemy.is_aspiring then
    if enemy:overlaps(hero, "origin") then
      enemy.is_aspiring = false
      enemy:eat_hero()
    end
  end
end

-- Start the enemy attack.
function enemy:start_aspirate()

  sprite:set_xy(0, 0)
  enemy.is_attacking = true

  -- Wait a short delay before starting the aspiration.
  sol.timer.start(enemy, before_aspiring_delay, function()
    enemy:set_can_attack(false)
    enemy.is_aspiring = true

    -- Bring hero closer while the enemy is aspiring.
    local function aspire_hero()
      local enemy_x, _, _ = enemy:get_position()
      local hero_x, _, _ = hero:get_position()
      local direction = enemy:get_direction2()

      -- If the hero is on the side (left/right) where the enemy is looking at
      if (direction == 0 and hero_x >= enemy_x) or (direction == 1 and hero_x <= enemy_x) then 
        enemy:attract_hero(1)
      end

      if enemy.is_aspiring then
        sol.timer.start(enemy, aspiration_on_hero_step_delay, function()
          aspire_hero()
        end)
      end
    end
    aspire_hero()

    -- Start aspire animation.
    sprite:set_animation("aspire")
    aspiration_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "_aspiration", "aspiration")
    aspiration_sprite:set_direction(sprite:get_direction())
    
    -- Make the enemy sprites elevate while aspiring.
    local function elevate(entity, angle)
      local movement = sol.movement.create("straight")
      movement:set_speed(elevation_speed)
      movement:set_max_distance(elevation_distance)
      movement:set_angle(angle)
      movement:set_ignore_obstacles(true)
      movement:start(entity)
      return movement
    end
    local elevate_movement = elevate(sprite, math.pi / 2.0)
    elevate(aspiration_sprite, math.pi / 2.0)

    -- Wait for a delay and start the touchdown movement.
    function elevate_movement:on_finished()
      sol.timer.start(enemy, elevated_duration, function()
        if enemy.is_aspiring then
          local touchdown_movement = elevate(sprite, 3.0 * math.pi / 2.0)
          elevate(aspiration_sprite, 3.0 * math.pi / 2.0)

          -- Reset default states a little after touching the ground.
          function touchdown_movement:on_finished() 
            sol.timer.start(enemy, finish_aspiration_delay, function()
              if enemy.is_aspiring then
                enemy:remove_sprite(aspiration_sprite)
                aspiration_sprite = nil
                enemy:reset_default_states()
              end
            end)
          end
        end
      end)
    end
  end)
end

-- Initialization.
function enemy:on_created()

  -- Game properties.
  enemy:set_life(4)
  enemy:set_damage(contact_damage)

  -- Behavior for each items.
  enemy:set_attack_consequence("sword", "ignored")
  enemy:set_attack_consequence("thrown_item", "ignored")
  enemy:set_attack_consequence("arrow", "ignored")
  enemy:set_attack_consequence("hookshot", "ignored")
  enemy:set_attack_consequence("fire", "ignored")
  enemy:set_attack_consequence("boomerang", 1)
  enemy:set_attack_consequence("explosion", 2)
  -- TODO enemy:set_attack_consequence("magic_rod", 2)

  -- Shadow.
  local shadow_sprite = enemy:create_sprite("entities/shadows/shadow", "shadow")
  enemy:bring_sprite_to_back(shadow_sprite)
end

-- Initial movement.
function enemy:on_restarted()
  enemy:reset_default_states()
end
