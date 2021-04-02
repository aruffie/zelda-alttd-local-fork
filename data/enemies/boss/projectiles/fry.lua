----------------------------------
--
-- Angler Fish's Fry.
--
-- Swimming enemy for sideview maps used in the Angler Fish fight.
-- Swim on a sinus curve over the horizontal axis.
--
----------------------------------

-- Global variables.
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local camera = map:get_camera()
local sprite = enemy:create_sprite("enemies/boss/angler_fish/fry")
local quarter = math.pi * 0.5
local circle = math.pi * 2.0

-- Configuration variables.
local swimming_speed = 40
local curve_height = 8
local curve_duration = 2000

-- Start the enemy movement.
local function start_swimming()

  -- Horizontal move.
  local angle = enemy:get_position() > camera:get_position() + camera:get_size() * 0.5 and math.pi or 0 
  local movement = enemy:start_straight_walking(angle, swimming_speed)
  movement:set_ignore_obstacles()

  -- Sinus curve on vertical axis.
  local elapsed_time = 0
  sol.timer.start(enemy, 10, function()
    elapsed_time = (elapsed_time + 10) % curve_duration
    sprite:set_xy(0, math.sin(elapsed_time / curve_duration * circle) * curve_height)
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

  -- States.
  enemy:set_obstacle_behavior("flying")
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  start_swimming()
end)
