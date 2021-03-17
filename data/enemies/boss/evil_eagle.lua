----------------------------------
--
-- Evil Eagle.
--
-- Description
--
-- Methods : enemy:start_fighting()
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

-- Configuration variables
local flying_speed = 32

-- Make the boss start the fight.
enemy:register_event("start_fighting", function(enemy)

  enemy:set_visible(true)
  enemy:set_can_attack(true)
  enemy:set_hero_weapons_reactions({
  	arrow = 2,
  	boomerang = 3,
  	explosion = 8,
  	sword = 2,
  	thrown_item = "protected",
  	fire = 6,
  	jump_on = "ignored",
  	hammer = "protected",
  	hookshot = 3,
  	magic_powder = "ignored",
  	shield = "protected",
  	thrust = 8
  })
end)

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(24)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 8)
  enemy:set_damage(8)

  enemy:set_visible(false)
  enemy:set_can_attack(false)
  enemy:set_invincible()
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  sprite:set_animation("flying")
end)
