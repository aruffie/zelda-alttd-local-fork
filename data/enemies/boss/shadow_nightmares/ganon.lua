----------------------------------
--
-- Shadow of Ganon.
--
-- Description.
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local hurt_shader = sol.shader.create("hurt")
local quarter = math.pi * 0.5
local axe
local is_hurt = false

-- Configuration variables.
local before_arming_duration = 800
local after_arming_duration = 800
local bats_count = 8
local between_bats_duration = 500
local aiming_duration = 1000
local hurt_duration = 600
local dying_duration = 2000

-- Check if the custom death as to be started before triggering the built-in hurt behavior.
local function hurt(damage)

  if is_hurt then
    return
  end
  is_hurt = true
  enemy:set_hero_weapons_reactions({sword = "protected", thrust = "protected"})

  -- Die if no more life.
  if enemy:get_life() - damage < 1 then

    enemy:start_death(function()
      sprite:set_shader(hurt_shader)
      sol.timer.start(enemy, dying_duration, function()
        finish_death()
      end)
    end)
    return
  end

  -- Make the enemy manually hurt, then shake, the disappear and reappear at its initial position.
  enemy:set_life(enemy:get_life() - damage)
  sprite:set_shader(hurt_shader)
  sol.timer.start(enemy, hurt_duration, function()
    is_hurt = false
    sprite:set_shader(nil)
    enemy:set_hero_weapons_reactions({
      sword = function() hurt(1) end,
      thrust = function() hurt(2) end
    })
  end)

  if enemy.on_hurt then
    enemy:on_hurt()
  end
end

-- Create a sub enemy and echo some of the main enemy methods.
local function create_sub_enemy(name, breed, x, y, direction)

  local sub_enemy = enemy:create_enemy({
      name = (enemy:get_name() or enemy:get_breed()) .. "_axe",
      breed = "boss/shadow_nightmares/projectiles/axe",
      direction = sprite:get_direction()
    })

  enemy:register_event("on_removed", function(enemy)
    if sub_enemy:exists() then
      sub_enemy:remove()
    end
  end)
  enemy:register_event("on_enabled", function(enemy)
    sub_enemy:set_enabled()
  end)
  enemy:register_event("on_disabled", function(enemy)
    sub_enemy:set_enabled(false)
  end)
  enemy:register_event("on_dead", function(enemy)
    if sub_enemy:exists() then
      sub_enemy:remove()
    end
  end)

  return sub_enemy
end

-- Start throwing the axe to the hero.
local function start_throwing()

  sprite:set_animation("aiming")
  axe:start_aiming(4, -26)
  sol.timer.start(enemy, aiming_duration, function()
    sprite:set_animation("throwing")
    axe:start_throwed(enemy)
  end)
end

-- Start invoking bats.
local function start_invoking()

  sprite:set_animation("invoking")
  axe:start_spinning(-28, -20)

  -- Start invoking bats.
  local bat_count = 0
  sol.timer.start(enemy, between_bats_duration, function()
    bat_count = bat_count + 1
    create_sub_enemy("bat", "boss/shadow_nightmares/projectiles/bat", bat_count * 20, 50, 2)
    return bat_count < bats_count
  end)
end

-- Start taking the axe in hand.
local function start_taking_axe()

  sprite:set_animation("waiting")
  sol.timer.start(enemy, before_arming_duration, function()
    sprite:set_animation("invoking")
    sprite:set_paused()

    -- Create the axe.
    axe = create_sub_enemy("axe", "boss/shadow_nightmares/projectiles/axe", 0, 0, sprite:get_direction())
    local axe_sprite = axe:get_sprite()

    -- Start invoking bats when the axe is holded or catched.
    local function holded()
      sprite:set_animation("stopped")
      axe_sprite:set_xy(-4, 24)
      sol.timer.start(enemy, after_arming_duration, function()
        start_invoking()
      end)
    end

    function axe:on_took()
      holded()
    end
    function axe:on_catched()
      holded()
    end
    axe:start_taking(-32, -16)
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(12)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions({
  	arrow = "protected",
  	boomerang = "protected",
  	explosion = "protected",
  	sword = function() hurt(1) end,
  	thrown_item = "protected",
  	fire = "protected",
  	jump_on = "ignored",
  	hammer = "protected",
  	hookshot = "protected",
  	magic_powder = "ignored",
  	shield = "protected",
  	thrust = function() hurt(2) end
  })

  -- States.
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  start_taking_axe()
end)
