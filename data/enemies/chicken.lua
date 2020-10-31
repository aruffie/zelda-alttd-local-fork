----------------------------------
--
-- Chicken.
--
-- Chicken enemy that can moves into 8 directions and run away on hit one time.
-- Make all chickens of the map fly to the hero on hurt many times.
--
-- Methods: enemy:set_angry()
--
----------------------------------

-- Global variables.
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local eighth = math.pi * 0.25
local is_afraid = false
local is_angry = false
local hurt_count = 0

-- Configuration variables
local walking_angles = {0, eighth, 2.0 * eighth, 3.0 * eighth, 4.0 * eighth, 5.0 * eighth, 6.0 * eighth, 7.0 * eighth}
local walking_speed = 40
local walking_minimum_distance = 16
local walking_maximum_distance = 96
local running_speed = 64
local pause_duration = 500
local pecking_probability = 0.5
local pecking_duration = 2000
local hurt_count_before_angry = 2
local take_off_duration = 1000
local flying_height = 24
local flying_speed = 160

-- Return a random position on the border of the screen.
local function get_random_position_on_screen_border()

  local x, y = camera:get_position()
  local width, height = camera:get_size()
  local mid_point = width + height
  local random_point = math.random(mid_point * 2)

  return x + (random_point > mid_point + width and 0 or math.min(width, random_point % mid_point)), 
          y + math.min(height, math.max(0, random_point - width) % mid_point)
end

-- Make the enemy run away on hurt and make all chicken attacks on too much hit received.
local function on_attack_received()

  is_afraid = true
  hurt_count = hurt_count + 1
  if not is_angry and hurt_count >= hurt_count_before_angry then
    for chicken in map:get_entities_by_type("enemy") do
      if chicken:get_breed() == enemy:get_breed() then
        chicken:start_angry()
      end
    end
  else
    enemy:hurt(0)
  end
end

-- Start the enemy run away movement.
local function start_running_away()

  local movement = enemy:start_straight_walking(0, running_speed)
  sprite:set_animation("running")

  local function update_angle()
    local angle = hero:get_angle(enemy)
    movement:set_angle(angle)
    sprite:set_direction(angle > quarter and angle < 3.0 * quarter and 2 or 0)
  end
  update_angle()

  function movement:on_position_changed()
    update_angle()
  end
  function movement:on_obstacle_reached()
    update_angle()
  end
end

-- Start the enemy walk movement.
local function start_walking()

  local angle = walking_angles[math.random(8)]
  enemy:start_straight_walking(angle, walking_speed, math.random(walking_minimum_distance, walking_maximum_distance), function()
    sol.timer.start(enemy, pause_duration, function()
      if math.random() < pecking_probability then
        sprite:set_animation("pecking")
        sol.timer.start(enemy, pecking_duration, function()
          sprite:set_animation("immobilized")
          sol.timer.start(enemy, pause_duration, function()
            enemy:restart()
          end)
        end)
      else
        enemy:restart()
      end
    end)
  end)
  sprite:set_animation("walking")
  sprite:set_direction(angle > quarter and angle < 3.0 * quarter and 2 or 0)
end

-- Make the enemy fly to the hero.
local function start_flying()

  local angle = enemy:get_angle(hero)
  local movement = enemy:start_straight_walking(angle, flying_speed)
  movement:set_ignore_obstacles()
  sprite:set_animation("flying")
  sprite:set_direction(angle > quarter and angle < 3.0 * quarter and 2 or 0)

  function movement:on_position_changed()
    if not enemy:is_watched(sprite) then
      enemy:restart()
    end
  end
end

-- Make the chicken angry, take off if visible then fly to the hero to hurt him.
function enemy:start_angry()

  enemy:stop_movement()
  sol.timer.stop_all(enemy)
  enemy:set_invincible()
  enemy:set_layer(map:get_max_layer())
  enemy:set_obstacle_behavior("flying")
  sprite:set_animation("flying")

  -- Make the chicken take off before flying if visible, else position it randomly on the border of the camera.
  if not is_angry then
    enemy:start_flying(take_off_duration, flying_height, function()
      sol.timer.start(enemy, pause_duration, function()
        start_flying()
      end)
    end)
  else
    enemy:set_position(get_random_position_on_screen_border())
    sprite:set_xy(0, -flying_height)
    start_flying()
  end

  is_angry = true
end

-- The enemy appears: set its properties.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(4)
  enemy:start_shadow()
end)

-- The enemy appears: set its properties.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(on_attack_received, {jump_on = "ignored"})

  -- States.
  enemy:set_damage(is_angry and 2 or 0)
  enemy:set_can_attack(is_angry)
  enemy:set_layer_independent_collisions(true)
  if not is_angry then
    if not is_afraid then
      start_walking()
    else
      start_running_away()
    end
  else
    enemy:start_angry()
  end
end)
