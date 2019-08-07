-- Lua script of enemy anti_kirby.
-- This script is executed every time an enemy with this model is created.

-- TODO sounds

-- Global variables
local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/" .. enemy:get_breed())
local aspiration_sprite = nil

-- Configuration variables
local suction_damage = 2
local contact_damage = 4

local attack_triggering_distance = 80

local walking_pause_duration = 1000
local eating_duration = 2000
local elevated_duration = 3000
local before_aspiring_delay = 200
local aspiration_on_hero_step_delay = 50
local before_walking_again_delay = 400

local walking_step_speed = 48
local walking_step_distance = 45
local spit_speed = 220
local spit_distance = 64
local elevation_speed = 8
local elevation_distance = 8

-- Check if an attack should be triggered, continue walking else.
function enemy:on_walk_finished()

  -- If the hero is near enough.
  local _, _, layer = enemy:get_position()
  local _, _, hero_layer = hero:get_position()
  local near_hero = (layer == hero_layer or enemy:has_layer_independent_collisions()) and enemy:get_distance(hero) < attack_triggering_distance

  if near_hero then
    enemy:start_aspirate()
  else
    sol.timer.start(enemy, walking_pause_duration, function()
      enemy:start_walking()
    end)
  end
end

-- Make the enemy move randomly and diagonally, and stop after each steps.
function enemy:start_walking()

  -- Random diagonal movement.
  math.randomseed(os.time())
  local direction = math.random(4)
  local movement = sol.movement.create("straight")
  movement:set_speed(walking_step_speed)
  movement:set_max_distance(walking_step_distance)
  movement:set_angle(math.pi / 4.0 + math.pi / 2.0 * direction)
  movement:set_smooth(true)
  movement:start(self)
  sprite:set_direction((direction == 1 or direction == 2) and 2 or 0) -- Only left or right possible.

  function movement:on_finished()
    enemy:on_walk_finished()
  end

  -- Consider the current move as finished if stuck.
  function movement:on_obstacle_reached()
    movement:stop()
    enemy:on_walk_finished()
  end
end

-- Reset default states after an enemy attack.
function enemy:reset_default_states()
  enemy.is_aspiring = false
  enemy.is_attacking = false
  enemy:set_can_attack(true)
  sprite:set_animation("walking")
  enemy:start_walking()
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
    movement:set_angle(sprite:get_direction() * math.pi / 2.0)
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

function enemy:on_update()

  -- Make the sprite jump if the enemy is not attacking.
  if not enemy.is_attacking then
    sprite:set_xy(0, -math.abs(math.cos(sol.main.get_elapsed_time() / 75.0) * 4.0))
  end

  -- If the hero touches the center of the enemy while aspiring, eat him.
  if enemy.is_aspiring then
    if enemy:overlaps(hero, "origin", sprite) then
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
      local enemy_x, enemy_y, enemy_layer = enemy:get_position()
      local hero_x, hero_y, hero_layer = hero:get_position()
      local direction = sprite:get_direction()
      if (direction == 0 and hero_x >= enemy_x) or (direction == 2 and hero_x <= enemy_x) then -- If the hero is on the side (left/right) where the enemy is looking at

        -- Simulate smooth movement.
        -- TODO Don't hardcode the hero bounding box.
        local move_x = math.max(math.min(enemy_x - hero_x, 1), -1)
        local move_y = math.max(math.min(enemy_y - hero_y, 1), -1)
        if string.match(map:get_ground(hero_x + move_x * 9, hero_y - 13, hero_layer), "wall")
            or string.match(map:get_ground(hero_x + move_x * 9, hero_y + 3, hero_layer), "wall")
            then -- Check if the x move would be valid regarding the hero bounding box.
          move_x = 0
        end
        if string.match(map:get_ground(hero_x + move_x - 8, hero_y + move_y + (move_y > 0 and 3 or -13), hero_layer), "wall")
            or string.match(map:get_ground(hero_x + move_x + 8, hero_y + move_y + (move_y > 0 and 3 or -13), hero_layer), "wall")
            then -- Check if the y move would be valid regarding the hero bounding box.
          move_y = 0
        end
        hero:set_position(hero_x + move_x, hero_y + move_y, hero_layer)
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
    aspiration_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/" .. enemy:get_breed() .. "_aspiration", "aspiration")
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
            sol.timer.start(enemy, before_walking_again_delay, function()
              enemy:remove_sprite(aspiration_sprite)
              aspiration_sprite = nil
              enemy:reset_default_states()
            end)
          end
        end
      end)
    end
  end)
end

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
  enemy:set_hammer_reaction(0)

  -- Shadow.
  local shadow_sprite = enemy:create_sprite("entities/shadows/shadow", "shadow")
  enemy:bring_sprite_to_back(shadow_sprite)

  -- Initial movement.
  enemy:reset_default_states()
end
