-- Lua script of enemy anti_kirby.
-- This script is executed every time an enemy with this model is created.

-- TODO sounds

-- Global variables
local enemy = ...
common_actions = require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local aspiration_sprite = nil
local eighth = math.pi * 0.25

-- Configuration variables
local suction_damage = 2
local contact_damage = 4

local walking_possible_angle = {eighth, 3.0 * eighth, 5.0 * eighth, 7.0 * eighth}
local attack_triggering_distance = 100
local aspirating_pixel_by_second = 88
local flying_height = 8

local walking_pause_duration = 1000
local eating_duration = 2000
local take_off_duration = 1000
local flying_duration = 3000
local landing_duration = 1000
local hat_duration = 10000
local before_aspiring_delay = 200
local finish_aspiration_delay = 400

local walking_speed = 48
local walking_distance = 45
local spit_speed = 220
local spit_distance = 64

-- Return the visual direction (left or right) depending on the sprite direction.
function enemy:get_direction2()

  if sprite:get_direction() < 2 then
    return 0
  end
  return 1
end

-- Start a random diagonal straight movement of a fixed distance and speed, and loop it with delay.
function enemy:start_walking()

  enemy:start_random_walking(walking_possible_angle, walking_speed, walking_distance, function()

    -- Start aspirate if the hero is near enough, continue walking else.
    if enemy:is_near(hero, attack_triggering_distance) then
      enemy:start_aspirate()
    else
      sol.timer.start(enemy, walking_pause_duration, function()
        enemy:start_walking()
      end)
    end
  end)
end

-- Make the enemy eat the hero.
function enemy:eat_hero()

  enemy.is_eating = true
  enemy:stop_aspirate()
  sprite:set_animation("eating_link")
  hero:set_visible(false)
  hero:freeze()
  
  sol.timer.start(enemy, eating_duration, function()
    enemy:spit_hero(true)
  end)
end

-- Make the enemy spit the hero if he was eaten.
function enemy:spit_hero(restart)

  if enemy.is_eating then

    enemy.is_eating = false

    -- Manually hurt and spit the hero after a delay.
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

    -- Change the enemy sprite
    enemy:remove_sprite(sprite)
    sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/anti_kirby_link")
    enemy:start_brief_effect("entities/effects/sparkle_small", "default", 0, 0)

    if restart then
      enemy:restart()
    end
  end
end

-- Start the enemy attack.
function enemy:start_aspirate()

  sprite:set_xy(0, 0)
  enemy.is_jumping = false

  -- Wait a short delay before starting the aspiration.
  sol.timer.start(enemy, before_aspiring_delay, function()
    enemy:set_can_attack(false)
    enemy.is_aspiring = true

    -- Bring hero closer while the enemy is aspiring if the hero is on the side (left/right) where the enemy is looking at and near enough.
    enemy:start_attracting(hero, aspirating_pixel_by_second, function()
      local enemy_x, _, _ = enemy:get_position()
      local hero_x, _, _ = hero:get_position()
      local direction = enemy:get_direction2()
      return enemy:is_near(hero, attack_triggering_distance) and ((direction == 0 and hero_x >= enemy_x) or (direction == 1 and hero_x <= enemy_x))
    end)

    -- Start aspire animation.
    sprite:set_animation("aspire")
    aspiration_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/aspiration", "aspiration")
    aspiration_sprite:set_direction(sprite:get_direction())

    -- Make the enemy sprites elevate while aspiring.
    enemy:start_flying(take_off_duration, flying_height, false, false)
  end)
end

-- Stop a possible running aspiration.
function enemy:stop_aspirate()

  enemy.is_aspiring = false
  if aspiration_sprite then
    enemy:remove_sprite(aspiration_sprite)
    aspiration_sprite = nil
  end
  sprite:set_xy(0, 0)
  sprite:stop_movement()
end

-- Event called when the enemy took off while aspiring.
function enemy:on_flying_took_off()

  -- Wait for a delay and start the landing movement.
  sol.timer.start(enemy, flying_duration, function()
    if enemy.is_aspiring then
      enemy:stop_flying(landing_duration, false)
    end
  end)
end

-- Event called when the enemy landed while aspiring.
function enemy:on_flying_landed() 

  -- Reset default states a little after touching the ground.
  sol.timer.start(enemy, finish_aspiration_delay, function()
    if enemy.is_aspiring then
      enemy:stop_aspirate()
      enemy:restart()
    end
  end)
end

-- Passive behaviors needing constant checking.
function enemy:on_update()

  if not enemy:is_immobilized() then
    -- Make the sprite jump if the enemy is not attacking and not immobilized.
    if enemy.is_jumping then
      sprite:set_xy(0, -math.abs(math.sin(sol.main.get_elapsed_time() * 0.01) * 4.0))
    end

    -- If the hero touches the center of the enemy while aspiring, eat him.
    if enemy.is_aspiring and enemy:overlaps(hero, "origin") then
      enemy:eat_hero()
      enemy:stop_attracting()
    end
  end
end

-- Stop a possible state on immobilized.
enemy:register_event("on_immobilized", function(enemy)
  enemy:stop_aspirate()
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(4)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_attack_consequence("sword", "ignored")
  enemy:set_attack_consequence("thrown_item", "ignored")
  enemy:set_attack_consequence("arrow", "ignored")
  enemy:set_attack_consequence("boomerang", 1)
  enemy:set_attack_consequence("explosion", 2)
  enemy:set_hookshot_reaction("ignored")
  enemy:set_hammer_reaction("ignored")
  enemy:set_fire_reaction(2)

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(contact_damage)
  enemy:stop_aspirate()
  enemy:spit_hero()
  enemy.is_jumping = true
  enemy:start_walking()
end)
