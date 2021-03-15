----------------------------------
--
-- Evil Eagle.
--
-- Description
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

-- Initialization.
enemy:register_event("on_created", function(enemy)

  enemy:set_life(12)
  enemy:set_size(16, 16)
  enemy:set_origin(8, 13)
end)

-- Restart settings.
enemy:register_event("on_restarted", function(enemy)

  -- Behavior for each items.
  enemy:set_hero_weapons_reactions({
    sword = 1
  })

  -- States.
  enemy:set_can_attack(true)
  enemy:set_damage(8)
  sprite:set_animation("flying")
end)
