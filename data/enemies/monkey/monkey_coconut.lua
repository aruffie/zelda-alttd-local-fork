-- Lua script of enemy coconut.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite
local movement

-- Include scripts
local audio_manager = require("scripts/audio_manager")

-- Event called when the enemy is initialized.
function enemy:on_created()

  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_invincible(true)
  enemy:set_damage(1)
  enemy:set_layer_independent_collisions(true)

end

-- Event called when the enemy should start or restart its movements.
-- This is called for example after the enemy is created or after
-- it was hurt or immobilized.
function enemy:on_restarted()

  local direction = enemy:get_sprite():get_direction()
  local angle = 4 * math.pi / 3
  if direction == 0 then
    angle = 5 * math.pi / 3
  end
  local movement = sol.movement.create("straight")
  movement:set_max_distance(80)
  movement:set_angle(angle)
  movement:set_speed(140)
  movement:set_ignore_obstacles(true)
  movement:start(enemy)
  function movement:on_finished()
    local distance = enemy:get_distance(hero)
    if distance < 250 then
      audio_manager:play_sound("misc/rock_shatter")
    end
    sprite:set_animation("destroyed", function()
      enemy:remove()
      end)
  end 
  
end
