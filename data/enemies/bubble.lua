----------------------------------
--
-- Bubble.
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
local quarter = math.pi * 0.5
local circle = math.pi * 2.0
local walking_angle
local is_hero_pushed = false

-- Configuration variables
local walking_angles = {eighth, 3.0 * eighth, 5.0 * eighth, 7.0 * eighth}
local walking_speed = 80

-- Makes the enemy go towards a diagonal direction and bounce on obstacle reached.
local function start_walking(angle)

  walking_angle = angle or walking_angles[math.random(4)]

  local movement = enemy:start_straight_walking(walking_angle, walking_speed, nil, function()
    start_walking(enemy:get_obstacles_bounce_angle(walking_angle))
  end)
  movement:set_smooth(false)
end

-- Make the enemy bounce on the shield.
local function bounce_on_shield()

  if is_hero_pushed then
    return
  end
  is_hero_pushed = true

  local normal_angle = hero:get_direction() * quarter
  if math.cos(math.abs(normal_angle - walking_angle)) <= 0 then -- Don't bounce if the enemy is walking away the hero.
    start_walking((2.0 * normal_angle - walking_angle + math.pi) % circle)
  end
  enemy:start_pushing_back(hero, 150, 100, sprite, nil, function()
    is_hero_pushed = false
  end)
end

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(1)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 8)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  enemy:set_hero_weapons_reactions({
  	arrow = "ignored",
  	boomerang = 1,
  	explosion = "ignored",
  	sword = "ignored",
  	thrown_item = "ignored",
  	fire = "protected",
  	jump_on = "ignored",
  	hammer = "ignored",
  	hookshot = "ignored",
  	magic_powder = 1,
  	shield = bounce_on_shield,
  	thrust = "ignored"
  })

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(2)
  start_walking()
end)
