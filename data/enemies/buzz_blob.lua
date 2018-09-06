-- Lua script of enemy buzz_blob.
-- This script is executed every time an enemy with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local hero_electric = false
local shader_electric = sol.shader.create("electric")
local sprite
local movement
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
    game:set_suspended(true)
    sprite:set_animation("buzzing")
    hero_electric = true
    sol.audio.play_sound("shock")
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
    end)

  end

end

map:register_event("on_draw", function(map, surface)
  if hero_electric then
    surface:set_shader(shader_electric)
  else
    surface:set_shader(nil)
  end
end)
