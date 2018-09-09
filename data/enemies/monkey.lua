-- Lua script of enemy monkey.
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
  enemy:set_life(1)
  enemy:set_damage(1)

end

-- Event called when the enemy should start or restart its movements.
-- This is called for example after the enemy is created or after
-- it was hurt or immobilized.
function enemy:on_restarted()

  enemy:attack(2)

end

function enemy:attack(direction)

  sprite:set_direction(direction)
  sprite:set_animation("throwing")
  enemy:create_coconut(direction)
  function sprite:on_animation_finished(animation)
    if animation == "throwing" then
      sprite:set_animation("walking")
      sol.timer.start(enemy, 200, function()
        if direction == 2 then
          enemy:attack(0)
        else
          enemy:wait(0)
        end
      end)
    end
  end
end

function enemy:wait()

  sprite:set_animation("walking")
  sol.timer.start(enemy, 2000, function()
    enemy:attack(2)
  end)
 
end

function enemy:create_coconut(direction)

    local coconut = enemy:create_enemy({
      breed = "monkey_coconut",
      layer= 2,
      x = 0,
      y = 0,
      direction = direction
    })
end