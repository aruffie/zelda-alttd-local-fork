-- Variables
local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local hero_electric = false
local effect_model = require("scripts/gfx_effects/electric")
local sprite
local movement

-- Include scripts
local audio_manager = require("scripts/audio_manager")
require("scripts/multi_events")

-- Event called when the enemy is initialized.
function enemy:on_created()

  -- Initialize the properties of your enemy here,
  -- like the sprite, the life and the damage.
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(1)
  enemy:set_damage(1)
  enemy:set_attack_consequence("sword",  "custom")

end

-- Event called when the enemy should start or restart its movements.
-- This is called for example after the enemy is created or after
-- it was hurt or immobilized.
function enemy:on_restarted()

  movement = sol.movement.create("target")
  movement:set_target(hero)
  movement:set_speed(48)
  movement:start(enemy)

end

function enemy:on_custom_attack_received(attack)

  if attack == "sword" then
    local camera = map:get_camera()
    local surface = camera:get_surface()
    hero:get_sprite():set_ignore_suspend(true)
    game:set_suspended(true)
    sprite:set_animation("buzzing")
    audio_manager:play_sound("others/sword_electricity")
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
    end)

  end

end

