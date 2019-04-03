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
local is_chase = false
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

  local m = sol.movement.create("straight")
  m:set_speed(0)
  m:start(self)
  local direction4 = math.random(4) - 1
  self:go(direction4)

end

function enemy:on_update()

  if self:get_distance(hero) <= 192 and is_chase == false then
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


function enemy:go(direction4)

  enemy:set_attack_consequence("sword", "protected")
  is_chase = false
  -- Set the sprite.
  sprite:set_animation("walking")
  sprite:set_direction(direction4)

  -- Set the movement.
  local max_distance = 40 + math.random(120)
  movement = sol.movement.create("straight")
  movement:set_max_distance(max_distance)
  movement:set_smooth(true)
  movement:set_speed(40)
  movement:set_angle(direction4 * math.pi / 2)
  movement:start(enemy)

end

function enemy:chase(direction4)

  is_chase = true
  sprite:set_animation("chase")
  movement:stop()
  local dxy = {
      { x =  8, y =  0},
      { x =  0, y = -8},
      { x = -8, y =  0},
      { x =  0, y =  8}
    }
    -- Check that we can make the move.
    local index = direction4 + 1
    if not self:test_obstacles(dxy[index].x * 2, dxy[index].y * 2) then
      sol.timer.start(enemy, 1000, function()
        local x, y = self:get_position()
        local angle = direction4 * math.pi / 2
        local m = sol.movement.create("straight")
        m:set_speed(96)
        m:set_angle(angle)
        m:set_max_distance(104)
        m:set_smooth(false)
        m:start(self)
        function m:on_finished()
          is_chase = false
          local direction4 = math.random(4) - 1
          enemy:go(direction4)
        end
        function m:on_obstacle_reached()
          is_chase = false
          local direction4 = math.random(4) - 1
          enemy:go(direction4)
        end
      end)
    state = "moving"
  end


end


function enemy:on_movement_finished(movement)

  local direction4 = math.random(4) - 1
  self:go(direction4)

end

function enemy:on_obstacle_reached(movement)

  local direction4 = math.random(4) - 1
  self:go(direction4)

end


function enemy:on_shield_collision(shield)

  local movement = enemy:get_movement()
  if movement ~= nil then
    movement:stop()
  end
  sprite:set_animation("renverse")
  enemy:set_attack_consequence("sword", 1)
  sol.timer.start(enemy, 2000, function()
    local direction4 = math.random(4) - 1
    self:go(direction4)
  end)
    

end
