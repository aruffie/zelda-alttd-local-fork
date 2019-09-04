-- Lua script of enemy cukeman.
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

local message_triggering_distance = 28

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

    -- Display a message if the hero is near enough, else electrify.
    if enemy:is_near(hero, message_triggering_distance) then
      game:start_dialog("enemies.cukeman." .. math.random(4))
    else
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
    end
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
    --TODO pegasus_boots = 2
  })

  -- States.
  enemy:set_damage(4)
  enemy:start_walking()
end)
