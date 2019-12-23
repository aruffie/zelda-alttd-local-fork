-- Lua script of enemy zol_red.
-- This script is executed every time an enemy with this model is created.

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local map = enemy:get_map()
local hero = map:get_hero()
local is_attacking, is_exhausted

-- Configuration variables
local walking_speed = 4
local jumping_speed = 64
local jumping_height = 12
local jumping_duration = 600
local attack_triggering_distance = 64
local shaking_duration = 1000
local exhausted_minimum_duration = 2000
local exhausted_maximum_duration = 4000

-- Start moving to the hero, and jump when he is close enough.
function enemy:start_walking()
  
  local movement = enemy:start_target_walking(hero, walking_speed)
  function movement:on_position_changed()
    if not is_attacking and not is_exhausted and enemy:is_near(hero, attack_triggering_distance) then
      is_attacking = true
      movement:stop()
      
      -- Shake for a short duration then start attacking.
      sprite:set_animation("shaking")
      sol.timer.start(enemy, shaking_duration, function()
         enemy:start_jump_attack()
      end)
    end
  end
end

-- Start jumping.
function enemy:start_jump_attack()

  -- Start jumping to the hero.
  local hero_x, hero_y, _ = hero:get_position()
  local enemy_x, enemy_y, _ = enemy:get_position()
  local angle = math.atan2(hero_y - enemy_y, enemy_x - hero_x) + math.pi
  enemy:start_jumping(jumping_duration, jumping_height, angle, jumping_speed)
  sprite:set_animation("jump")
end

-- Create two gels on weak attack received.
local function on_weak_attack_received()

  enemy:set_invincible()

  local x, y, layer = enemy:get_position()
  local function create_gel(x_offset)
    local gel = map:create_enemy({
      name = (enemy:get_name() or enemy:get_breed()) .. "_gel",
      breed = "gel",
      x = x + x_offset,
      y = y,
      layer = layer,
      direction = enemy:get_direction4_to(hero)
    })

    -- Make gel invincible for a few time to let a potential sword attack finish.
    gel:set_invincible()
    sol.timer.start(map, 300, function()
      gel:restart()
    end)

    -- Call an enemy:on_enemy_created(gel) event.
    if enemy.on_enemy_created then
      enemy:on_enemy_created(gel)
    end
  end

  create_gel(-5)
  create_gel(5)
  enemy:hurt(enemy:get_life()) -- Kill the enemy instead of removing it to trigger dying events.
  enemy:set_visible(false)
end

-- Start walking again when the attack finished.
enemy:register_event("on_jump_finished", function(enemy)
  enemy:restart()
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()

  -- Workaround : Don't play the dying sound added by enemy meta script.
  enemy.is_stoic = true
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- TODO Get the exact list of weapons that kills the zol immediately, and ones that split it into gels.
  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(on_weak_attack_received, {jump_on = "ignored"})

  -- States.
  is_attacking = false
  is_exhausted = true
  sol.timer.start(enemy, math.random(exhausted_minimum_duration, exhausted_maximum_duration), function()
    is_exhausted = false
  end)
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_damage(2)
  enemy:start_walking()
end)