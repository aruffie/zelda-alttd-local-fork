----------------------------------
--
-- Crow.
--
-- Flying enemy that wait for the hero to be close enough, then take off and attack him.
-- Possibly set deeply sleeping from the outside to not wake him up when the hero is close, and let wake_up() manually when needed.
--
-- Methods : enemy:wake_up()
--
-- Properties : is_heavy_sleeper
--
----------------------------------

-- Global variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local quarter = math.pi * 0.5
local circle = math.pi * 2.0
local is_awake = false
local turning_time = 0

-- Configuration variables
local is_heavy_sleeper = enemy:get_property("is_heavy_sleeper") == "true"
local after_awake_delay = 1000
local take_off_duration = 1000
local targeting_hero_duration = 1000
local turning_away_duration = 500
local flying_speed = 120
local flying_height = 24
local triggering_distance = 60

-- Set the sprite direction 0 or 2 depending on the given angle.
local function set_sprite_direction2(angle)

  angle = angle % circle
  sprite:set_direction(angle > quarter and angle < 3.0 * quarter and 2 or 0)
end

-- Return the angle from the enemy sprite to given entity.
local function get_angle_from_sprite(sprite, entity)

  local x, y, _ = enemy:get_position()
  local sprite_x, sprite_y = sprite:get_xy()
  local entity_x, entity_y, _ = entity:get_position()

  return math.atan2(y - entity_y + sprite_y, entity_x - x - sprite_x)
end

-- Start the flying movement.
local function start_flying()

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions(1, {
    boomerang = 2,
    hookshot = 2,
    thrust = 2,
    jump_on = "ignored"
  })

  -- Begin by going to the hero.
  local angle = get_angle_from_sprite(sprite, hero)
  local movement = enemy:start_straight_walking(angle, flying_speed)
  movement:set_ignore_obstacles(true)
  set_sprite_direction2(angle)

  -- Slightly turn to the hero for some time, then turn away from him for some time and finish straight.
  local is_targeting_hero = true
  local is_turning_away = false
  local angle_step = 0.02
  sol.timer.start(enemy, 10, function()
    local angle_to_hero = get_angle_from_sprite(sprite, hero)
    local is_hero_on_left = (angle - angle_to_hero) % circle > math.pi
    angle = angle + (is_hero_on_left and angle_step or -angle_step)
    movement:set_angle(angle)
    set_sprite_direction2(angle)
    return is_targeting_hero or is_turning_away
  end)
  sol.timer.start(enemy, targeting_hero_duration, function()
    is_targeting_hero = false
    if not is_turning_away then
      angle_step = -angle_step
      is_turning_away = true
      return turning_away_duration
    end
    return
  end)

  -- Remove the enemy when off screen.
  function movement:on_position_changed()
    if not is_targeting_hero and not enemy:is_watched(sprite, true) then
      enemy:remove()
    end
  end
end

-- Wait for the hero to be close enough and start flying if yes.
local function wait()

  is_awake = true
  sol.timer.start(enemy, 100, function()
    if enemy:get_distance(hero) < triggering_distance then
      enemy:wake_up()
      return false
    end
    return true
  end)
end

-- Make the enemy wake up.
function enemy:wake_up()

  is_awake = true
  local x, _, _ = enemy:get_position()
  local hero_x, _, _ = hero:get_position()

  sprite:set_direction(hero_x < x and 2 or 0)
  sprite:set_animation("flying")
  enemy:start_flying(take_off_duration, flying_height, function()
    sol.timer.start(enemy, after_awake_delay, function()
      start_flying()
    end)
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(2)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
  enemy:start_shadow()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_invincible()

  -- States.
  sprite:set_xy(0, is_awake and -flying_height or 0)
  sprite:set_animation("waiting")
  enemy:set_obstacle_behavior("flying")
  enemy:set_can_attack(true)
  enemy:set_damage(4)
  enemy:set_layer_independent_collisions(true)

  -- Wait for hero to be near enough 
  if is_awake then
    start_flying()
  elseif not is_heavy_sleeper then
    wait()
  end
end)
