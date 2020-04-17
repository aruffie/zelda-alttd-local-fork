----------------------------------
--
-- Ghini.
--
-- Target a random visible point on the map and go to it with acceleration and deceleration, then target another visible point.
-- Possibly can start asleep, in case it has to be manually wake_up() from outside this script.
--
-- Methods : enemy:start_moving()
--           enemy:wake_up()
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

-- Configuration variables
local is_sleeping = enemy:get_property("is_sleeping") == "true"
local after_awake_delay = 1000
local take_off_duration = 1000
local flying_speed = 80
local flying_height = 16
local flying_acceleration = 16
local flying_deceleration = 48

-- Start the enemy flying movement.
function enemy:start_moving()

  local enemy_x, enemy_y, _ = enemy:get_position()
  local camera_x, camera_y = camera:get_position()
  local camera_width, camera_height = camera:get_size()

  -- Target a random point.
  local limit_box = {x = camera_x + 64, y = camera_y + 64, width = camera_width - 128, height = camera_height - 128}
  local target_x = math.random(limit_box.x, limit_box.x + limit_box.width)
  local target_y = math.random(limit_box.y, limit_box.y + limit_box.height)

  -- Start moving to the target with acceleration.
  local movement = enemy:start_impulsion(target_x, target_y, flying_speed, flying_acceleration, flying_deceleration)
  movement:set_ignore_obstacles(true)
  sprite:set_direction(target_x < enemy_x and 2 or 0)

  -- Target a new random point when target reached.
  function movement:on_decelerating()
    enemy:start_moving()
  end
end

-- Make the enemy wake up.
function enemy:wake_up()
  enemy:set_enabled(true)
  enemy:start_flying(take_off_duration, flying_height, function()
    sol.timer.start(enemy, after_awake_delay, function()
      is_sleeping = false
      enemy:start_moving()
    end)
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(8)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()

  -- Don't show the enemy if sleeping.
  if is_sleeping then
    enemy:set_enabled(false)
  end
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(1, {
    hookshot = 2,
    thrust = 2,
    arrow = 4,
    fire = 4,
    boomerang = 8,
    bomb = 8,
    jump_on = "ignored",
  })

  -- States.
  sprite:set_xy(0, 0)
  enemy:set_obstacle_behavior("flying")
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  enemy:set_layer_independent_collisions(true)

  -- Start a fly that already took off if not sleeping.
  if not is_sleeping then
    sprite:set_xy(0, -flying_height)
    sol.timer.start(enemy, 10, function() -- Workaround: The camera position is 0, 0 here when entering a map, wait a frame before starting the move.
      enemy:start_moving()
    end)
  end
end)
