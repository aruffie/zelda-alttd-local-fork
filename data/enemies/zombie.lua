----------------------------------
--
-- Zombie.
--
-- Start invisible and appear after a random time at a random position, then go to the hero direction.
-- The apparition point may be restricted to an area if the corresponding custom property is filled with a valid area, else the point will always be a visible one.
-- Disappear after some time or obstacle reached.
--
-- Properties : area
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)
require("scripts/multi_events")

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local eighth = math.pi * 0.25

-- Configuration variables
local area = enemy:get_property("area")
local walking_speed = 32
local walking_minimum_duration = 2000
local walking_maximum_duration = 4000
local waiting_minimum_duration = 2000
local waiting_maximum_duration = 4000

-- Return the layer of the given position.
local function get_ground_layer(x, y)

  for ground_layer = map:get_max_layer(), map:get_min_layer(), -1 do
    if map:get_ground(x, y, ground_layer) ~= "empty" then
      return ground_layer
    end
  end
end

-- Make the enemy disappear.
local function disappear()

  sprite:set_animation("disappearing", function()
    enemy:restart()
  end)
end

-- Start the enemy movement.
local function start_walking()

  local movement = enemy:start_target_walking(hero, walking_speed)
  movement:set_smooth(false)

  local function stop_walking()
    if movement then
      movement:stop()
      movement = nil
      disappear()
    end
  end

  function movement:on_obstacle_reached()
    stop_walking()
  end
  sol.timer.start(enemy, math.random(walking_minimum_duration, walking_maximum_duration), function()
    stop_walking()
  end)
end

-- Make the enemy appear at a random position on the ground layer.
local function appear()

  -- Postpone to the next frame if the random position would be over an obstacle.
  local x, y = enemy:get_position()
  local random_x, random_y = enemy:get_random_position_in_area(area or camera)
  local layer = get_ground_layer(random_x, random_y)
  enemy:set_layer(layer or enemy:get_layer())
  if not layer or enemy:test_obstacles(random_x - x, random_y - y) then
    sol.timer.start(enemy, 10, function()
      appear()
    end)
    return
  end

  enemy:set_position(random_x, random_y)
  enemy:set_visible()
  sprite:set_animation("appearing", function()

    enemy:set_hero_weapons_reactions({
    	arrow = 1,
    	boomerang = 1,
    	explosion = 1,
    	sword = 1,
    	thrown_item = 1,
    	fire = 1,
    	jump_on = "ignored",
    	hammer = 1,
    	hookshot = 1,
    	magic_powder = 1,
    	shield = "protected",
    	thrust = 1
    })
    enemy:set_can_attack(true)
    
    start_walking()
  end)
end

-- Wait a few time and appear.
local function wait()

  sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    if not camera:overlaps(enemy:get_max_bounding_box()) then
      return true
    end
    appear()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 8)
  enemy:set_origin(8, 5)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_invincible()

  -- States.
  enemy:set_visible(false)
  enemy:set_can_attack(false)
  enemy:set_damage(2)
  wait()
end)

