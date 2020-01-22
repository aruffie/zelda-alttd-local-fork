-- Lua script of enemy hardhat_beetle.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local game = enemy:get_game()
local behavior = require("enemies/lib/towards_hero")
local properties = {
  sprite = "enemies/" .. enemy:get_breed(),
  life = 1,
  damage = 4,
  normal_speed = 24,
  faster_speed = 24,
  detection_distance = 220,
  obstacle_behavior = "normal"
}

-- The enemy appears: set its properties.
enemy:register_event("on_created", function(enemy)

  behavior:create(enemy, properties)
  enemy:set_attack_consequence("sword", 0)
  enemy:set_arrow_reaction(0)
  enemy:set_attack_consequence("thrown_item", 0)
  enemy:set_attack_consequence("explosion", 1)
  enemy:set_attack_consequence("boomerang", 'immobilized')
  enemy:set_hammer_reaction(0)
  
end)