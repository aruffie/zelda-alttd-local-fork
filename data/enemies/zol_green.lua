----------------------------------
--
-- Zol Green.
--
-- Start invisible and appear when the hero is close enough, then pounce several times to him.
--
-- Methods : enemy:start_pouncing()
--           enemy:appear()
--           enemy:disappear()
--           enemy:wait()
--
----------------------------------

-- Variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local jump_count, current_max_jump
local shadow

-- Configuration variables.
local walking_speed = 4
local jumping_speed = 64
local jumping_height = 12
local jumping_duration = 600
local shaking_duration = 1000
local between_jump_duration = 500
local max_jump_combo = 8
local triggering_distance = 60

-- Start pouncing to the hero.
function enemy:start_pouncing()

  local hero_x, hero_y, _ = hero:get_position()
  local enemy_x, enemy_y, _ = enemy:get_position()
  local angle = math.atan2(hero_y - enemy_y, enemy_x - hero_x) + math.pi
  enemy:start_jumping(jumping_duration, jumping_height, angle, jumping_speed, function()

    -- Contine jumping or disappear on jump finished.
    sprite:set_animation("shaking")
    if enemy:get_distance(hero) > triggering_distance or jump_count >= current_max_jump then
      enemy:disappear()
    else
      sol.timer.start(enemy, between_jump_duration, function()
        jump_count = jump_count + 1
        enemy:start_pouncing()
      end)
    end
  end)
  sprite:set_animation("jumping")
end

-- Make the enemy appear.
function enemy:appear()

  enemy:set_visible()
  sprite:set_animation("appearing", function()

    enemy:set_hero_weapons_reactions({
    	arrow = 1,
    	boomerang = 1,
    	explosion = 1,
    	sword = 1,
    	thrown_item = 1,
    	fire = 1,
    	jump_on = "ignored",
    	hammer = 1,
    	hookshot = 1,
    	magic_powder = 1,
    	shield = "protected",
    	thrust = 1
    })

    sprite:set_animation("shaking")
    enemy:set_can_attack(true)
    sol.timer.start(enemy, 1000, function()
      jump_count = 1
      current_max_jump = math.random(max_jump_combo)
      enemy:start_pouncing()
    end)
  end)
end

-- Make the enemy disappear.
function enemy:disappear()

  sprite:set_animation("disappearing", function()
    enemy:restart()
  end)
end

-- Wait for the hero to be close enough and appear if yes.
function enemy:wait()

  sol.timer.start(enemy, 100, function()
    if enemy:get_distance(hero) < triggering_distance then
      enemy:appear()
      return false
    end
    return true
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  shadow = enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_invincible()

  -- States.
  sprite:set_xy(0, 0)
  enemy:set_obstacle_behavior("normal")
  enemy:set_damage(2)
  enemy:set_can_attack(false)
  enemy:set_visible(false)
  enemy:wait()
end)
