-- Lua script of enemy buzz_blob.
-- This script is executed every time an enemy with this model is created.

-- Global variables.
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
local effect_model = require("scripts/gfx_effects/electric")
local audio_manager = require("scripts/audio_manager")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local hero_electric = false
local eighth = math.pi * 0.25

-- Configuration variables
local walking_possible_angles = {0, eighth, 2.0 * eighth, 3.0 * eighth, 4.0 * eighth, 5.0 * eighth, 6.0 * eighth, 7.0 * eighth}
local walking_speed = 16
local walking_distance_grid = 16
local walking_max_move_by_step = 6
local walking_pause_duration = 1500
local cukeman_shaking_duration = 500

-- Start the enemy movement.
function enemy:start_walking()

  enemy:start_straight_walking(walking_possible_angles[math.random(8)], walking_speed, walking_distance_grid * math.random(walking_max_move_by_step), function()
    enemy:start_walking()
  end)
end

-- Handle custom sword and magic powder attacks.
enemy:register_event("on_custom_attack_received", function(enemy, attack)

  -- Electrify the hero on sword attack.
  if attack == "sword" then

    local camera = map:get_camera()
    local surface = camera:get_surface()
    hero:get_sprite():set_ignore_suspend(true)
    game:set_suspended(true)
    sprite:set_animation("buzzing")
    audio_manager:play_sound("hero/shock")
    hero:set_animation("electrocute")
    effect_model.start_effect(surface, game, 'in', false)
    local camera = map:get_camera()
    local shake_config = {
        count = 32,
        amplitude = 4,
        speed = 180,
    }
    camera:shake(shake_config, function()
        hero_electric = false
        game:set_suspended(false)
        sprite:set_animation("walking")
        hero:unfreeze()
        hero:start_hurt(enemy:get_damage())
        enemy:remove_life(1)
    end)

  -- Transform into Cukeman on magic powder attack.
  elseif attack == "magic_powder" then

    local x, y, layer = enemy:get_position()
    cukeman = enemy:create_enemy({breed = "cukeman"})
    enemy:remove()

    -- Make the Cukeman shake for some time and then restart.
    cukeman:set_invincible()
    cukeman:stop_movement()
    sol.timer.stop_all(cukeman)
    cukeman:get_sprite():set_animation("shaking")
    sol.timer.start(cukeman, cukeman_shaking_duration, function()
      cukeman:restart()
    end)
  end
end)

-- The enemy appears: set its properties.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(4)
end)

-- The enemy appears: set its properties.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(4, {
    hookshot = "immobilized",
    sword = "custom",
    magic_powder = "custom"})

  -- States.
  enemy:set_damage(4)
  enemy:start_walking()
end)
