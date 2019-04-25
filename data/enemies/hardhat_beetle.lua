-- Lua script of enemy hardhat_beetle.
-- This script is executed every time an enemy with this model is created.

-- Variables
local enemy = ...
local game = enemy:get_game()
local behavior = require("enemies/lib/towards_hero")
local properties = {
  sprite = "enemies/" .. enemy:get_breed(),
  life = 1,
  damage = 1,
  normal_speed = 24,
  faster_speed = 24,
  detection_distance = 220,
  obstacle_behavior = "normal"
}

-- The enemy appears: set its properties.
function enemy:on_created()

  behavior:create(enemy, properties)
  enemy:set_invincible(true)
  enemy:set_attack_consequence("arrow", "custom")
  enemy:set_attack_consequence("boomerang", "custom")
  enemy:set_attack_consequence("sword", "custom")
  enemy:set_attack_consequence("thrown_item", "custom")
  enemy:set_fire_reaction("custom")
  enemy:set_hammer_reaction("custom")
  enemy:set_hookshot_reaction("custom")
  
end

function enemy:on_custom_attack_received(attack)

  sol.timer.stop_all(enemy)  -- Stop the towards_hero behavior.
  local hero = enemy:get_map():get_hero()
  local angle = hero:get_angle(enemy)
  local movement = sol.movement.create("straight")
  movement:set_speed(128)
  --movement:set_ignore_obstacles(true)
  movement:set_angle(angle)
  movement:start(enemy)
  sol.timer.start(enemy, 400, function()
    enemy:restart()
  end)

end