-- Lua script of enemy "gel red".
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local max_distance = 50
local is_awake = false
local game, map, sprite

-- The enemy appears: set its properties.
function enemy:on_created()

  game = self:get_game()
  map = self:get_map()
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(1)
  enemy:set_damage(1)
  enemy:set_obstacle_behavior("flying")
end

function enemy:on_restarted()

  sprite:set_animation("invisible")
  sol.timer.start(enemy, 50, function()
    local tx, ty, _ = map:get_hero():get_position()
    if enemy:get_distance(tx, ty) < max_distance then
      if is_awake == false then
        is_awake = true
        local direction4 = math.random(4) - 1
        self:go(direction4)
        return false
      end
    end
    return true
  end)

end

function enemy:on_movement_finished(movement)

  local direction4 = math.random(4) - 1
  enemy:go(direction4)
end


function enemy:go(direction4)

   -- Set the sprite.
  sprite:set_animation("walking")
  sprite:set_direction(direction4)

  -- Set the movement.
  local max_distance = 40 + math.random(120)
  local m = sol.movement.create("straight")
  m:set_max_distance(max_distance)
  m:set_smooth(true)
  m:set_speed(40)
  m:set_angle(direction4 * math.pi / 2)
  m:set_ignore_obstacles(true)
  m:start(enemy)
end


