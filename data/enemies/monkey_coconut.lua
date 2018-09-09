-- Lua script of enemy monkey_coconut.
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
local sprite
local movement

-- Event called when the enemy is initialized.
function enemy:on_created()

  -- Initialize the properties of your enemy here,
  -- like the sprite, the life and the damage.
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_invincible(true)
  enemy:set_damage(1)

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
    movement:start(enemy)
    function movement:on_finished()
      local distance = enemy:get_distance(hero)
      if distance < 170 then
        sol.audio.play_sound("stone")
      end
      enemy:remove()
    end 
  
end
