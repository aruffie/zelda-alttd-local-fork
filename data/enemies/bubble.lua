-- Lua script of enemy bubble.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local last_direction8 = 0

-- An obstacle is reached: make the Star bounce.
function enemy:on_obstacle_reached()

  local dxy = {
    { x =  1, y =  0},
    { x =  1, y = -1},
    { x =  0, y = -1},
    { x = -1, y = -1},
    { x = -1, y =  0},
    { x = -1, y =  1},
    { x =  0, y =  1},
    { x =  1, y =  1}
  }

  -- The current direction is last_direction8:
  -- try the three other diagonal directions.
  local try1 = (last_direction8 + 2) % 8
  local try2 = (last_direction8 + 6) % 8
  local try3 = (last_direction8 + 4) % 8
  if not self:test_obstacles(dxy[try1 + 1].x, dxy[try1 + 1].y) then
    enemy:go(try1)
  elseif not self:test_obstacles(dxy[try2 + 1].x, dxy[try2 + 1].y) then
    enemy:go(try2)
  else
    enemy:go(try3)
  end
end

-- Makes the Star go towards a diagonal direction (1, 3, 5 or 7).
function enemy:go(direction8)

  local movement = sol.movement.create("straight")
  movement:set_speed(80)
  movement:set_smooth(false)
  movement:set_angle(direction8 * math.pi / 4)
  movement:start(self)
  last_direction8 = direction8
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 8)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions("ignored", {
    boomerang = 1,
    magic_powder = 1
  })

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  enemy:go(math.random(4) * 2 - 1)
end)
