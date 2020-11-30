----------------------------------
--
-- Bubble Giant.
--
-- Go towards a diagonal direction and bounce on obstacle reached.
--
----------------------------------

-- Variables
local enemy = ...
require("enemies/lib/common_actions").learn(enemy)

local map = enemy:get_map()
local hero = map:get_hero()
local sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
local eighth = math.pi * 0.25
local circle = math.pi * 2.0

-- Configuration variables
local walking_angles = {eighth, 3.0 * eighth, 5.0 * eighth, 7.0 * eighth}
local walking_speed = 80

-- Makes the enemy go towards a diagonal direction and bounce on obstacle reached.
local function start_walking(angle)

  angle = angle or walking_angles[math.random(4)]

  local movement = enemy:start_straight_walking(angle, walking_speed, nil, function()
    start_walking(enemy:get_obstacles_bounce_angle(angle))
  end)
  movement:set_smooth(false)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(32, 32)
  enemy:set_origin(16, 16)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_hero_weapons_reactions({
  	arrow = "ignored",
  	boomerang = "protected",
  	explosion = "ignored",
  	sword = "ignored",
  	thrown_item = "ignored",
  	fire = "protected",
  	jump_on = "ignored",
  	hammer = "ignored",
  	hookshot = "ignored",
  	magic_powder = "ignored",
  	shield = "ignored",
  	thrust = "ignored"
  })

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  start_walking()
end)
