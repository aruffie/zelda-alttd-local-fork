----------------------------------
--
-- Zombie.
--
-- Start invisible and appear after a random time at a random position, then go to the hero direction.
-- Disappear after some time or obstacle reached.
--
-- Methods : enemy:start_walking()
--           enemy:appear()
--           enemy:disappear()
--           enemy:wait()
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
local walking_speed = 32
local walking_minimum_duration = 2000
local walking_maximum_duration = 4000
local waiting_minimum_duration = 2000
local waiting_maximum_duration = 4000

-- Return a random visible position.
local function get_random_visible_position()

  local x, y, _ =  camera:get_position()
  local width, height = camera:get_size()

  return math.random(x, x + width), math.random(y, y + height)
end

-- Start the enemy movement.
function enemy:start_walking()

  local movement = enemy:start_target_walking(hero, walking_speed)
  movement:set_smooth(false)

  local function disappear()
    if movement then
      movement:stop()
      movement = nil
      enemy:disappear()
    end
  end

  function movement:on_obstacle_reached()
    disappear()
  end
  sol.timer.start(enemy, math.random(walking_minimum_duration, walking_maximum_duration), function()
    disappear()
  end)
end

-- Make the enemy appear at a random position.
function enemy:appear()

  -- Postpone to the next frame if the random position would be over an obstacle.
  local x, y, _ = enemy:get_position()
  local random_x, random_y = get_random_visible_position()
  if enemy:test_obstacles(random_x - x, random_y - y) then
    sol.timer.start(enemy, 10, function()
      enemy:appear()
    end)
    return
  end

  enemy:set_position(random_x, random_y)
  enemy:set_visible()
  sprite:set_animation("appearing", function()

    -- Behavior for each items.
    enemy:set_hero_weapons_reactions(1, {jump_on = "ignored"})
    enemy:set_can_attack(true)
    
    enemy:start_walking()
  end)
end

-- Make the enemy disappear.
function enemy:disappear()

  sprite:set_animation("disappearing", function()
    enemy:restart()
  end)
end

-- Wait a few time and appear.
function enemy:wait()

  sol.timer.start(enemy, math.random(waiting_minimum_duration, waiting_maximum_duration), function()
    if not camera:overlaps(enemy:get_max_bounding_box()) then
      return true
    end
    enemy:appear()
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 24)
  enemy:set_origin(8, 21)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- States.
  enemy:set_visible(false)
  enemy:set_can_attack(false)
  enemy:set_damage(2)
  enemy:set_invincible()
  enemy:wait()
end)

