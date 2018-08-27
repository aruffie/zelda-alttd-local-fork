-- Lua script of enemy spike.
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
local timer
local activation_distance = 16

-- Event called when the enemy is initialized.
function enemy:on_created()

  -- Initialize the properties of your enemy here,
  -- like the sprite, the life and the damage.
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(3)
  enemy:set_damage(1)
  enemy:set_default_behavior_on_hero_shield("normal_shield_push")

end


-- Event called when the enemy should start or restart its movements.
-- This is called for example after the enemy is created or after
-- it was hurt or immobilized.
function enemy:on_restarted()

  enemy:go()

end

function enemy:on_update()

  if self:get_distance(hero) <= 192 then
    -- Check whether the hero is close.
    local x, y = self:get_position()
    local hero_x, hero_y = hero:get_position()
    local dx, dy = hero_x - x, hero_y - y

    if math.abs(dy) < activation_distance then
      if dx > 0 then
        self:chase(0)
      else
        self:chase(2)
      end
    end
    if math.abs(dx) < activation_distance then
      if dy > 0 then
        self:chase(3)
      else
        self:chase(1)
      end
    end
  end
end


function enemy:go()

  sprite:set_animation("walking")
  movement = sol.movement.create("target")
  movement:set_target(hero)
  movement:set_speed(48)
  movement:start(enemy)

end

function enemy:chase(direction4)

  sprite:set_animation("chase")

local dxy = {
    { x =  8, y =  0},
    { x =  0, y = -8},
    { x = -8, y =  0},
    { x =  0, y =  8}
  }

  -- Check that we can make the move.
  local index = direction4 + 1
  if not self:test_obstacles(dxy[index].x * 2, dxy[index].y * 2) then

    state = "moving"

    local x, y = self:get_position()
    local angle = direction4 * math.pi / 2
    local m = sol.movement.create("straight")
    m:set_speed(96)
    m:set_angle(angle)
    m:set_max_distance(104)
    m:set_smooth(false)
    m:start(self)
  end


end


function enemy:on_obstacle_reached()

  self:go()

end

function enemy:on_movement_finished()

  self:go()

end


function enemy:on_shield_collision(shield)

  movement:stop()
  sprite:set_animation("renverse")
  sol.timer.start(enemy, 2000, function()
    enemy:go()
  end)
    

end
