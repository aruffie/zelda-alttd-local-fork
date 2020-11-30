----------------------------------
--
-- Ghini.
--
-- Target a random point on the map and go to it with acceleration and deceleration, then target another point.
-- The targeted point may be restricted to an area if the corresponding custom property is filled with a valid area, else the targeted point will always be a visible one.
-- May start disabled and manually wake_up() from outside this script, in which case it will elevate slowly before starting its fly.
--
-- Methods : enemy:wake_up()
--
-- Properties : area
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local circle = math.pi * 2.0
local is_waking_up = false

-- Configuration variables
local area = enemy:get_property("area")
local after_awake_delay = 1000
local take_off_duration = 1000
local flying_speed = 80
local flying_height = 16
local flying_acceleration = 40
local flying_deceleration = 40

-- Start the enemy flying movement.
local function start_moving()

  local x, y = enemy:get_position()
  local target_x, target_y = enemy:get_random_position_in_area(area or camera)
  local angle = enemy:get_angle(target_x, target_y)
  local distance = enemy:get_distance(target_x, target_y)

  -- Start moving to the target with acceleration.
  local movement = enemy:start_impulsion(angle, flying_speed, flying_acceleration, flying_deceleration, distance)
  movement:set_ignore_obstacles(true)
  sprite:set_direction(target_x < x and 2 or 0)

  -- Target a new random point when target reached.
  function movement:on_decelerating()
    start_moving()
  end
end

-- Enable the enemy and make him wake up then fly.
function enemy:wake_up()

  is_waking_up = true
  sol.timer.stop_all(enemy)
  enemy:stop_movement()
  enemy:set_enabled(true)
  sprite:set_xy(0, 0)
  enemy:start_flying(take_off_duration, flying_height, function()
    sol.timer.start(enemy, after_awake_delay, function()
      is_waking_up = false
      enemy:restart()
    end)
  end)
end

-- Mark as wake up if hurt.
enemy:register_event("on_hurt", function(enemy)
  is_waking_up = false
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(8)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_hero_weapons_reactions({
  	arrow = 4,
  	boomerang = 8,
  	explosion = 8,
  	sword = 1,
  	thrown_item = 1,
  	fire = 4,
  	jump_on = "ignored",
  	hammer = 1,
  	hookshot = 2,
  	magic_powder = 1,
  	shield = "protected",
  	thrust = 2
  })

  -- States.
  sprite:set_xy(0, 0)
  enemy:set_obstacle_behavior("flying")
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  enemy:set_layer_independent_collisions(true)

  -- Start a fly that already took off.
  if not is_waking_up then
    sprite:set_xy(0, -flying_height)
    sol.timer.start(enemy, 10, function() -- Workaround: The camera position is 0, 0 here when entering a map, wait a frame before starting the move.
      start_moving()
    end)
  end
end)
