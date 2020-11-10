----------------------------------
--
-- Anti Kirby.
--
-- Moves diagonally on a small distance, stops and restart.
-- Start a long aspiration covering left or right side if the hero is near enough after a walking step.
--
-- Methods : enemy:start_walking()
--           enemy:eat_hero()
--           enemy:spit_hero()
--           enemy:start_aspiration()
--           enemy:stop_aspiration()
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local aspiration_sprite = nil
local eighth = math.pi * 0.25

-- Configuration variables
local suction_damage = 2
local contact_damage = 4

local walking_angles = {eighth, 3.0 * eighth, 5.0 * eighth, 7.0 * eighth}
local attack_triggering_distance = 100
local aspirating_pixel_by_second = 88
local flying_height = 8

local walking_pause_duration = 1000
local eating_duration = 2000
local take_off_duration = 1000
local flying_duration = 3000
local landing_duration = 1000
local before_aspiring_delay = 200
local finish_aspiration_delay = 400

local walking_speed = 48
local walking_distance = 45
local spit_speed = 220
local spit_distance = 64

-- Return the visual direction (left or right) depending on the sprite direction.
local function get_direction2()

  if sprite:get_direction() < 2 then
    return 0
  end
  return 1
end

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_angles[math.random(4)], walking_speed, walking_distance, function()

    -- Start aspiration if the hero is near enough, continue walking else.
    if enemy:is_near(hero, attack_triggering_distance) then
      enemy:start_aspiration()
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
  enemy:stop_aspiration()
  sprite:set_animation("eating_link")
  hero:set_visible(false)
  hero:freeze()
  
  sol.timer.start(enemy, eating_duration, function()
    enemy:spit_hero()
  end)
end

-- Make the enemy spit the hero if he was eaten.
function enemy:spit_hero()

  if enemy.is_eating then

    enemy.is_eating = false

    -- Manually hurt and spit the hero after a delay.
    hero:start_hurt(suction_damage)
    hero:set_position(enemy:get_position())
    hero:set_visible()

    local movement = sol.movement.create("straight")
    movement:set_speed(spit_speed)
    movement:set_max_distance(spit_distance)
    movement:set_angle(get_direction2() * math.pi)
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

    enemy:restart()
  end
end

-- Start the enemy attack.
function enemy:start_aspiration()

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
      local direction = get_direction2()
      return enemy:is_near(hero, attack_triggering_distance) and ((direction == 0 and hero_x >= enemy_x) or (direction == 1 and hero_x <= enemy_x))
    end)

    -- Start aspire animation.
    sprite:set_animation("aspire")
    aspiration_sprite = enemy:create_sprite("enemies/" .. enemy:get_breed() .. "/aspiration", "aspiration")
    aspiration_sprite:set_direction(sprite:get_direction())

    -- Make the enemy sprites fly while aspiring.
    enemy:start_flying(take_off_duration, flying_height, function()
      sol.timer.start(enemy, flying_duration, function()
        if enemy.is_aspiring then
          enemy:stop_flying(landing_duration, function()

            -- Reset default states a little after touching the ground.
            sol.timer.start(enemy, finish_aspiration_delay, function()
              if enemy.is_aspiring then
                enemy:stop_aspiration()
                enemy:restart()
              end
            end)
          end)
        end
      end)
    end)
  end)
end

-- Stop a possible running aspiration.
function enemy:stop_aspiration()

  enemy.is_aspiring = false
  if aspiration_sprite then
    enemy:remove_sprite(aspiration_sprite)
    aspiration_sprite = nil
  end
  sprite:set_xy(0, 0)
  sprite:stop_movement()
end

-- Passive behaviors needing constant checking.
enemy:register_event("on_update", function(enemy)

  if enemy:is_immobilized() then
    return
  end

  -- Make the sprite jump if the enemy is not attacking and not immobilized.
  if enemy.is_jumping then
    sprite:set_xy(0, -math.abs(math.sin(sol.main.get_elapsed_time() * 0.01) * 4.0))
  end

  -- If the hero touches the center of the enemy while aspiring, eat him.
  if enemy.is_aspiring and enemy:overlaps(hero, "origin") then
    enemy:eat_hero()
    enemy:stop_attracting()
  end
end)

-- Stop a possible state on immobilized.
enemy:register_event("on_immobilized", function(enemy)
  enemy:stop_aspiration()
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(4)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_hero_weapons_reactions({
    arrow = "protected",
    boomerang = 1,
    explosion = 2,
    sword = "protected",
    thrown_item = "protected",
    fire = 2,
    jump_on = "ignored",
    hammer = "protected",
    hookshot = "protected",
    magic_powder = "ignored",
    shield = "protected",
    thrust = "protected"
  })

  -- States.
  sprite:set_xy(0, 0)
  enemy:set_obstacle_behavior("normal")
  enemy:set_can_attack(true)
  enemy:set_damage(contact_damage)
  enemy:stop_aspiration()
  enemy:spit_hero()
  enemy.is_jumping = true
  enemy:start_walking()
end)
