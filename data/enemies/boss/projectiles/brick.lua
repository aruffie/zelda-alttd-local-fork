----------------------------------
--
-- Angler Fish's Brick.
--
-- Falling enemy for sideview maps used in the Angler Fish fight.
-- Fall as a sinus curve on the vertical axis.
--
----------------------------------

-- Global variables.
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/boss/angler_fish/brick")
local quarter = math.pi * 0.5
local circle = math.pi * 2.0

-- Configuration variables.
local falling_speed = 40
local curve_height = 4
local curve_duration = 1000

-- Start the enemy movement.
local function start_falling()

  -- Vertical move.
  local movement = enemy:start_straight_walking(3 * quarter, falling_speed)
  movement:set_ignore_obstacles()

  -- Sinus curve on horizontal axis.
  local elapsed_time = 0
  sol.timer.start(enemy, 10, function()
    elapsed_time = (elapsed_time + 10) % curve_duration
    sprite:set_xy(math.sin(elapsed_time / curve_duration * circle) * curve_height, 0)
    return true
  end)

  function movement:on_position_changed()
    if not camera:overlaps(enemy:get_bounding_box()) then
      enemy:start_death()
    end
  end
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions({
  	arrow = "protected",
  	boomerang = "protected",
  	explosion = "protected",
  	sword = "protected",
  	thrown_item = "protected",
  	fire = "protected",
  	jump_on = "ignored",
  	hammer = "protected",
  	hookshot = "protected",
  	magic_powder = "protected",
  	shield = "protected",
  	thrust = "protected"
  })

  -- States.
  sprite:set_animation("default")
  enemy:set_obstacle_behavior("flying")
  enemy:set_can_attack(true)
  enemy:set_damage(6)
  start_falling()
end)
